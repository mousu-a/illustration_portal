import { Controller } from "@hotwired/stimulus";

const X_SCRIPT_URL = "https://platform.twitter.com/widgets.js";

export default class extends Controller {
  connect() {
    this.convertLinkToCard();
  }

  async convertLinkToCard() {
    const targetLink = this.element.querySelector(".archive__url");
    if (!targetLink) return;

    const url = targetLink.href;
    if (!url) return;

    try {
      const response = await fetch(`/api/metadata?url=${encodeURIComponent(url)}`, {
        headers: { "X-Requested-With": "XMLHttpRequest" },
      });
      if (!response.ok) return;

      const metadata = await response.json();
      if (metadata.html) {
        this.replaceLinkToXPost(targetLink, metadata.html);
      } else {
        this.replaceLinkToCard(targetLink, metadata);
      }
    } catch (error) {
      console.error("metadataの取得に失敗しました:", error);
    }
  }

  replaceLinkToXPost(targetLink, html) {
    const container = document.createElement("div");
    container.className = "x-post-embed";
    container.innerHTML = html;

    targetLink.insertAdjacentElement("beforebegin", container);
    targetLink.remove();
    loadXScript(container);
  }

  replaceLinkToCard(targetLink, metadata) {
    const LinkCard = generateLinkCard(targetLink.href, metadata);

    targetLink.insertAdjacentElement("beforebegin", LinkCard);
    targetLink.remove();
  }
}

function generateLinkCard(url, metadata) {
  const cardContainer = document.createElement("a");
  cardContainer.href = url;
  cardContainer.target = "_blank";
  cardContainer.rel = "noopener";
  cardContainer.className = "link-card";

  const header = document.createElement("div");
  header.className = "link-card__header";

  if (metadata.favicon_url) {
    const favicon = document.createElement("img");
    favicon.className = "link-card__favicon";
    favicon.src = metadata.favicon_url;
    favicon.alt = "";
    header.appendChild(favicon);
  }

  const title = document.createElement("p");
  title.className = "link-card__title";
  title.textContent = metadata.title;
  header.appendChild(title);

  cardContainer.appendChild(header);

  if (metadata.image_url) {
    const image = document.createElement("img");
    image.className = "link-card__image";
    image.src = metadata.image_url;
    image.alt = "";
    cardContainer.appendChild(image);
  }

  const domain = document.createElement("p");
  domain.className = "link-card__domain";
  domain.textContent = new URL(url).hostname;
  cardContainer.appendChild(domain);

  return cardContainer;
}

let xScriptPromise;
function loadXScript(container) {
  xScriptPromise ??= new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = X_SCRIPT_URL;
    script.async = true;
    script.charset = "utf-8";
    script.onload = () => resolve();
    script.onerror = () => {
      xScriptPromise = null;
      script.remove();
      reject(new Error(`${X_SCRIPT_URL} の読み込みに失敗しました`));
    };
    document.head.appendChild(script);
  });

  xScriptPromise
    .then(() => window.twttr.widgets.load(container))
    .catch((error) => console.error(error));
}
