import { ImageOff } from "lucide-react";
import { useState, type ImgHTMLAttributes } from "react";

/** Shows a neutral placeholder when the photo is missing, broken, or a 1x1 "not found" pixel. */
export function SafeImage({ src, alt, className, ...rest }: ImgHTMLAttributes<HTMLImageElement>) {
  const [failed, setFailed] = useState(!src);
  if (failed) {
    return (
      <div role="img" aria-label={alt} className={`flex items-center justify-center bg-muted text-muted-foreground ${className ?? ""}`}>
        <ImageOff className="size-8 opacity-50" />
      </div>
    );
  }
  return (
    <img
      src={src}
      alt={alt}
      className={className}
      onError={() => setFailed(true)}
      onLoad={(event) => { if (event.currentTarget.naturalWidth < 10) setFailed(true); }}
      {...rest}
    />
  );
}
