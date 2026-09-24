import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.convertLinkToCard();
  }

  async convertLinkToCard() {
    const targetLink = this.element.querySelector(".tweet__url");
    if (!targetLink) return;

    const url = targetLink.href;
    if (!url) return;

    try {
      const response = await fetch(`/api/metadata?url=${encodeURIComponent(url)}`, {
        headers: { "X-Requested-With": "XMLHttpRequest" },
      });
      if (!response.ok) return;

      const metadata = await response.json();
      this.replaceLinkToCard(targetLink, metadata);
    } catch (error) {
      console.error("metadataの取得に失敗しました:", error);
    }
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

  if (metadata.image_url) {
    const image = document.createElement("img");
    image.className = "link-card__image";
    image.src = metadata.image_url;
    image.alt = "";
    cardContainer.appendChild(image);
  } else {
    cardContainer.classList.add("link-card--no-image");
  }

  const footer = document.createElement("div");
  footer.className = "link-card__footer";

  const title = document.createElement("p");
  title.className = "link-card__title";
  title.textContent = metadata.title;
  footer.appendChild(title);

  if (metadata.favicon_url) {
    const favicon = document.createElement("img");
    favicon.className = "link-card__favicon";
    favicon.src = metadata.favicon_url;
    favicon.alt = "";
    footer.appendChild(favicon);
  }

  cardContainer.appendChild(footer);

  return cardContainer;
}
