import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static outlets = ["tag-mode"];

  replace(e) {
    const link = e.currentTarget;
    const { addHref, switchHref } = link.dataset;
    link.href = this.tagModeOutlet.addMode ? addHref : switchHref;
  }
}
