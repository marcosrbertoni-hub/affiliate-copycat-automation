import airfryerImage from "@/assets/airfryer.jpg";
import coffeeImage from "@/assets/cafeteira.jpg";
import heroImage from "@/assets/review-hero.jpg";

export type Category = {
  name: string;
  slug: string;
  color: "pet" | "bebe" | "beleza" | "casa" | "cozinha" | "livros";
};

export type Product = {
  name: string;
  badge: string;
  image: string;
  price: string;
  url: string;
  summary: string;
  specs: Record<string, string>;
  pros: string[];
  cons: string[];
};

export type Post = {
  slug: string;
  title: string;
  description: string;
  category: Category;
  publishedAt: string;
  readingTime: string;
  image: string;
  intro: string[];
  products: Product[];
  guide: { title: string; paragraphs: string[] }[];
  faq: { question: string; answer: string }[];
};

export const categories: Category[] = [
  { name: "Pet", slug: "pet", color: "pet" },
  { name: "Bebê", slug: "bebe", color: "bebe" },
  { name: "Beleza", slug: "beleza", color: "beleza" },
  { name: "Casa", slug: "casa", color: "casa" },
  { name: "Cozinha", slug: "cozinha", color: "cozinha" },
  { name: "Livros", slug: "livros", color: "livros" },
];

const houseCategory: Category = { name: "Casa", slug: "casa", color: "casa" };
const kitchenCategory: Category = { name: "Cozinha", slug: "cozinha", color: "cozinha" };
const airFryerNames = ["Air Fryer Digital 5L", "Air Fryer Compact 4L", "Air Fryer Oven 12L"] as const;
const headphoneNames = ["Sound Pro ANC", "Wave Lite", "Studio Max"] as const;

const baseProducts: Product[] = [
  {
    name: "Cafeteira Automática Barista Pro",
    badge: "Nossa escolha",
    image: coffeeImage,
    price: "R$ 2.499,00",
    url: "https://www.amazon.com.br/dp/B0C0FFEE01?tag=concorrente-20&linkCode=old",
    summary:
      "Entrega café consistente com poucos toques, moagem integrada e ajuste de intensidade. É a opção mais completa para quem busca praticidade sem abrir mão do sabor.",
    specs: { Marca: "Barista", Pressão: "15 bar", Reservatório: "1,8 L", Potência: "1.450 W" },
    pros: ["Moedor integrado e silencioso", "Preparo rápido e personalizável", "Limpeza automática"],
    cons: ["Ocupa mais espaço na bancada", "Investimento inicial elevado"],
  },
  {
    name: "Cafeteira Espresso Compact",
    badge: "Melhor custo-benefício",
    image: heroImage,
    price: "R$ 699,90",
    url: "https://www.amazon.com.br/dp/B0C0FFEE02?ref_=generic&th=0",
    summary:
      "Modelo compacto com vaporizador eficiente e comandos diretos. Uma escolha equilibrada para começar a preparar espresso e bebidas com leite em casa.",
    specs: { Marca: "Casa Café", Pressão: "15 bar", Reservatório: "1,2 L", Potência: "1.100 W" },
    pros: ["Bom espresso pelo preço", "Fácil de usar", "Cabe em cozinhas pequenas"],
    cons: ["Não possui moedor", "Bandeja de gotejamento pequena"],
  },
  {
    name: "Cafeteira Premium Touch",
    badge: "Top de linha",
    image: coffeeImage,
    price: "R$ 3.799,00",
    url: "https://www.amazon.com.br/dp/B0C0FFEE03?tag=outra-tag-20",
    summary:
      "Painel sensível ao toque, receitas salvas e acabamento refinado. Indicada para famílias que preparam diferentes bebidas ao longo do dia.",
    specs: { Marca: "Prima", Pressão: "19 bar", Reservatório: "2,2 L", Potência: "1.500 W" },
    pros: ["Grande variedade de receitas", "Acabamento premium", "Perfis de usuário"],
    cons: ["Preço alto", "Exige limpeza frequente do sistema de leite"],
  },
];

const commonGuide = [
  {
    title: "Como escolher a melhor cafeteira para sua rotina",
    paragraphs: [
      "Comece avaliando quantas xícaras são preparadas por dia e quanto tempo você quer dedicar ao processo. Máquinas automáticas priorizam conveniência; modelos manuais dão mais controle sobre a extração.",
      "Observe também o espaço disponível, a facilidade de limpeza e o custo recorrente de grãos, cápsulas ou filtros. A melhor compra é aquela que continua prática depois da novidade inicial.",
    ],
  },
  {
    title: "Pressão, potência e temperatura importam?",
    paragraphs: [
      "Para espresso doméstico, 15 bar declarados são comuns, mas estabilidade térmica e moagem adequada têm impacto maior no resultado. Potência elevada ajuda no aquecimento rápido e na produção de vapor.",
    ],
  },
];

const commonFaq = [
  { question: "Qual tipo de cafeteira faz o café mais encorpado?", answer: "Máquinas de espresso, quando usadas com grãos frescos e moagem adequada, produzem bebidas mais concentradas e encorpadas." },
  { question: "Cafeteira automática consome muita energia?", answer: "O consumo costuma ser moderado porque o maior gasto acontece apenas durante o aquecimento. O modo de espera automático reduz o uso diário." },
  { question: "É preciso limpar a máquina todos os dias?", answer: "Bandeja, bicos e sistema de leite devem ser higienizados após o uso. A descalcificação completa segue a frequência indicada pelo fabricante." },
  { question: "Vale a pena comprar uma máquina com moedor?", answer: "Sim, principalmente para quem valoriza aroma e praticidade. Moer na hora preserva características que se perdem rapidamente após a moagem." },
];

export const posts: Post[] = [
  {
    slug: "melhores-cafeteiras",
    title: "Melhores cafeteiras: 7 opções testadas em 2026",
    description: "Comparamos cafeteiras automáticas e espresso para encontrar as melhores escolhas para cada rotina.",
    category: kitchenCategory, publishedAt: "12 de setembro de 2026", readingTime: "11 min de leitura", image: coffeeImage,
    intro: ["Avaliamos preparo, consistência, limpeza e custo de uso para selecionar as cafeteiras que realmente facilitam a rotina.", "Nossa seleção combina testes práticos, ficha técnica e opiniões recorrentes de compradores verificados."],
    products: baseProducts, guide: commonGuide, faq: commonFaq,
  },
  {
    slug: "melhores-air-fryers",
    title: "Melhores air fryers para comprar em 2026",
    description: "Modelos eficientes, espaçosos e fáceis de limpar para diferentes tamanhos de família.",
    category: kitchenCategory, publishedAt: "8 de setembro de 2026", readingTime: "9 min de leitura", image: airfryerImage,
    intro: ["Selecionamos as air fryers com melhor equilíbrio entre capacidade, potência e facilidade de limpeza."],
    products: baseProducts.map((product, index) => ({ ...product, name: airFryerNames[index] ?? product.name, image: airfryerImage })), guide: commonGuide, faq: commonFaq,
  },
  {
    slug: "melhores-fones-bluetooth",
    title: "Melhores fones Bluetooth de 2026",
    description: "Comparamos conforto, bateria e cancelamento de ruído para indicar os melhores fones sem fio.",
    category: houseCategory, publishedAt: "2 de setembro de 2026", readingTime: "10 min de leitura", image: heroImage,
    intro: ["Testamos os pontos que fazem diferença no uso real: conforto prolongado, conexão, microfone e autonomia."],
    products: baseProducts.map((product, index) => ({ ...product, name: headphoneNames[index] ?? product.name, image: heroImage })), guide: commonGuide, faq: commonFaq,
  },
];

export const featuredPosts = posts;

export function getPost(slug: string) {
  return posts.find((post) => post.slug === slug);
}