import { createElement } from "lwc";
import TokenActions from "c/tokenActions";
import issueTokenAura from "@salesforce/apex/TokenService.issueTokenAura";
import revokeTokenAura from "@salesforce/apex/TokenService.revokeTokenAura";

describe("c-token-actions", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  function createComponent(props = {}) {
    const element = createElement("c-token-actions", { is: TokenActions });
    element.recordId = props.recordId || "001000000000001AAA";
    if (props.selectedTokenId) {
      element.selectedTokenId = props.selectedTokenId;
    }
    document.body.appendChild(element);
    return element;
  }

  async function flushPromises() {
    return new Promise((resolve) => {
      jest.requireActual("timers").setImmediate(resolve);
    });
  }

  it("Revoke button is disabled when no token is selected", async () => {
    const element = createComponent();
    await Promise.resolve();

    const revokeBtn = element.shadowRoot.querySelector(
      'lightning-button[data-id="revoke-btn"]'
    );
    expect(revokeBtn).not.toBeNull();
    expect(revokeBtn.disabled).toBe(true);
  });

  it("Revoke button is enabled when a token is selected", async () => {
    const element = createComponent({ selectedTokenId: "a001000000000001" });
    await Promise.resolve();

    const revokeBtn = element.shadowRoot.querySelector(
      'lightning-button[data-id="revoke-btn"]'
    );
    expect(revokeBtn.disabled).toBe(false);
  });

  it("calls issueTokenAura with correct params on Issue button click", async () => {
    issueTokenAura.mockResolvedValue({ Id: "a001000000000099" });

    const element = createComponent();
    await Promise.resolve();

    const scopeInput = element.shadowRoot.querySelector(
      'lightning-input[data-id="scope-input"]'
    );
    scopeInput.value = "read:all";
    scopeInput.dispatchEvent(new CustomEvent("change"));

    const dateInput = element.shadowRoot.querySelector(
      'lightning-input[data-id="expiry-input"]'
    );
    dateInput.value = "2026-12-31";
    dateInput.dispatchEvent(new CustomEvent("change"));

    await Promise.resolve();

    const issueBtn = element.shadowRoot.querySelector(
      'lightning-button[data-id="issue-btn"]'
    );
    issueBtn.click();

    await flushPromises();

    expect(issueTokenAura).toHaveBeenCalledWith({
      accountId: "001000000000001AAA",
      expiryDateStr: "2026-12-31",
      scope: "read:all"
    });
  });

  it("fires tokenrefresh event and clears inputs after successful issue", async () => {
    issueTokenAura.mockResolvedValue({ Id: "a001000000000099" });

    const element = createComponent();
    await Promise.resolve();

    const refreshHandler = jest.fn();
    element.addEventListener("tokenrefresh", refreshHandler);

    const issueBtn = element.shadowRoot.querySelector(
      'lightning-button[data-id="issue-btn"]'
    );
    issueBtn.click();

    await flushPromises();

    expect(issueTokenAura).toHaveBeenCalled();
    expect(refreshHandler).toHaveBeenCalled();
  });

  it("does not fire tokenrefresh on failed issue", async () => {
    issueTokenAura.mockRejectedValue({
      body: { message: "Issue failed" }
    });

    const element = createComponent();
    await Promise.resolve();

    const refreshHandler = jest.fn();
    element.addEventListener("tokenrefresh", refreshHandler);

    const issueBtn = element.shadowRoot.querySelector(
      'lightning-button[data-id="issue-btn"]'
    );
    issueBtn.click();

    await flushPromises();

    expect(issueTokenAura).toHaveBeenCalled();
    expect(refreshHandler).not.toHaveBeenCalled();
  });

  it("calls revokeTokenAura with correct tokenId on Revoke button click", async () => {
    revokeTokenAura.mockResolvedValue(undefined);

    const element = createComponent({
      selectedTokenId: "a001000000000001"
    });
    await Promise.resolve();

    const revokeBtn = element.shadowRoot.querySelector(
      'lightning-button[data-id="revoke-btn"]'
    );
    revokeBtn.click();

    await flushPromises();

    expect(revokeTokenAura).toHaveBeenCalledWith({
      tokenId: "a001000000000001"
    });
  });

  it("fires tokenrefresh event after successful revoke", async () => {
    revokeTokenAura.mockResolvedValue(undefined);

    const element = createComponent({
      selectedTokenId: "a001000000000001"
    });
    await Promise.resolve();

    const refreshHandler = jest.fn();
    element.addEventListener("tokenrefresh", refreshHandler);

    const revokeBtn = element.shadowRoot.querySelector(
      'lightning-button[data-id="revoke-btn"]'
    );
    revokeBtn.click();

    await flushPromises();

    expect(refreshHandler).toHaveBeenCalled();
  });
});
