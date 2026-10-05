#!/usr/bin/env python3
"""Daily drip-feeding for Google's Indexing API.

The queue is intentionally persistent in data/indexing-state.json:
- successful URLs are never submitted again;
- failed URLs are retried before new URLs;
- each run makes at most 200 publish attempts;
- the source can be a local TXT file or a sitemap URL.
"""

from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

from google.auth.transport.requests import AuthorizedSession
from google.oauth2 import service_account

DAILY_LIMIT = 200
INDEXING_ENDPOINT = "https://indexing.googleapis.com/v3/urlNotifications:publish"
SCOPES = ["https://www.googleapis.com/auth/indexing"]

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE = ROOT / "data" / "indexing-urls.txt"
STATE_FILE = ROOT / "data" / "indexing-state.json"
LOG_DIR = ROOT / "logs" / "indexing"


def unique_urls(urls: Iterable[str]) -> list[str]:
    seen: set[str] = set()
    result: list[str] = []
    for raw in urls:
        url = raw.strip()
        if not url or url.startswith("#"):
            continue
        if not (url.startswith("https://") or url.startswith("http://")):
            continue
        if url not in seen:
            seen.add(url)
            result.append(url)
    return result


def load_txt(path: Path) -> list[str]:
    if not path.exists():
        return []
    return unique_urls(path.read_text(encoding="utf-8").splitlines())


def fetch_text(url: str) -> str:
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "affiliate-copycat-automation/1.0"},
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8", errors="replace")


def parse_sitemap(xml_text: str) -> tuple[list[str], list[str]]:
    root = ET.fromstring(xml_text)
    tag = root.tag.rsplit("}", 1)[-1]
    locs = [
        element.text.strip()
        for element in root.iter()
        if element.tag.rsplit("}", 1)[-1] == "loc" and element.text
    ]
    if tag == "sitemapindex":
        return [], unique_urls(locs)
    return unique_urls(locs), []


def load_sitemap(url: str, visited: set[str] | None = None) -> list[str]:
    visited = visited or set()
    if url in visited:
        return []
    visited.add(url)

    urls, child_sitemaps = parse_sitemap(fetch_text(url))
    for child in child_sitemaps:
        urls.extend(load_sitemap(child, visited))
    return unique_urls(urls)


def load_source() -> list[str]:
    source = os.getenv("INDEXING_SOURCE", str(DEFAULT_SOURCE)).strip()
    if source.startswith(("http://", "https://")):
        urls = load_sitemap(source)
    else:
        path = Path(source)
        if not path.is_absolute():
            path = ROOT / path
        urls = load_txt(path)
    if not urls:
        raise RuntimeError(
            f"Nenhuma URL encontrada na fonte: {source}. "
            "Preencha data/indexing-urls.txt ou informe INDEXING_SOURCE com um sitemap."
        )
    return urls


def load_state() -> dict:
    if not STATE_FILE.exists():
        return {"successful": [], "retry": [], "attempted": []}
    try:
        state = json.loads(STATE_FILE.read_text(encoding="utf-8"))
        return {
            "successful": unique_urls(state.get("successful", [])),
            "retry": unique_urls(state.get("retry", [])),
            "attempted": unique_urls(state.get("attempted", [])),
        }
    except (json.JSONDecodeError, OSError) as exc:
        raise RuntimeError(f"Estado inválido em {STATE_FILE}: {exc}") from exc


def save_state(state: dict) -> None:
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "updated_at": datetime.now(timezone.utc).isoformat(),
        "successful": state["successful"],
        "retry": state["retry"],
        "attempted": state["attempted"],
    }
    STATE_FILE.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def get_credentials():
    raw = os.getenv("GOOGLE_INDEXING_SERVICE_ACCOUNT_JSON", "").strip()
    if not raw:
        raise RuntimeError(
            "Secret GOOGLE_INDEXING_SERVICE_ACCOUNT_JSON não foi configurado."
        )
    try:
        info = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise RuntimeError(
            "GOOGLE_INDEXING_SERVICE_ACCOUNT_JSON não contém JSON válido."
        ) from exc
    return service_account.Credentials.from_service_account_info(info, scopes=SCOPES)


def submit(session: AuthorizedSession, url: str) -> tuple[bool, int, str]:
    body = json.dumps({"url": url, "type": "URL_UPDATED"}).encode("utf-8")
    request = urllib.request.Request(
        INDEXING_ENDPOINT,
        data=body,
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        method="POST",
    )
    try:
        response = session.request(
            request.method,
            request.full_url,
            data=body,
            headers=dict(request.header_items()),
            timeout=30,
        )
        status = response.status_code
        text = response.text[:500].replace("\n", " ")
        return status == 200, status, text
    except Exception as exc:
        return False, 0, str(exc)[:500].replace("\n", " ")


def append_log(lines: list[str]) -> Path:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    path = LOG_DIR / f"{datetime.now(timezone.utc):%Y-%m-%d}.log"
    with path.open("a", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")
    return path


def main() -> int:
    urls = load_source()
    state = load_state()

    successful = set(state["successful"])
    attempted = set(state["attempted"])
    retry = [url for url in state["retry"] if url not in successful]

    retry_set = set(retry)
    fresh = [url for url in urls if url not in attempted and url not in retry_set]

    batch = unique_urls(retry + fresh)[:DAILY_LIMIT]
    if not batch:
        print("Fila concluída: não há URLs novas ou pendentes para envio.")
        return 0

    credentials = get_credentials()
    session = AuthorizedSession(credentials)

    now = datetime.now(timezone.utc)
    log_lines = [
        f"UTC: {now.isoformat()}",
        f"source_urls: {len(urls)}",
        f"batch_size: {len(batch)}",
        f"daily_limit: {DAILY_LIMIT}",
    ]

    retry_next = [url for url in retry if url not in batch]
    success_count = 0
    failure_count = 0

    for index, url in enumerate(batch, start=1):
        ok, status, detail = submit(session, url)
        state["attempted"].append(url)

        if ok:
            successful.add(url)
            success_count += 1
            log_lines.append(f"OK\t{index:03d}\t{status}\t{url}")
        else:
            retry_next.append(url)
            failure_count += 1
            log_lines.append(f"FAIL\t{index:03d}\t{status}\t{url}\t{detail}")

    state["successful"] = sorted(successful)
    state["retry"] = unique_urls(retry_next)
    state["attempted"] = unique_urls(state["attempted"])
    save_state(state)
    log_path = append_log(log_lines)

    print(
        f"Enviadas {len(batch)} URLs; sucesso={success_count}; "
        f"falhas={failure_count}; log={log_path}"
    )

    if len(batch) < DAILY_LIMIT and len(urls) > len(successful):
        print("Aviso: havia menos de 200 URLs disponíveis nesta execução.")

    return 0 if failure_count == 0 else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise SystemExit(130)
    except Exception as exc:
        print(f"ERRO: {exc}", file=sys.stderr)
        raise SystemExit(1)
