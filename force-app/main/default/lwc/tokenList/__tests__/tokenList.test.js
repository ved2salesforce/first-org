import { createElement } from "lwc";
import TokenList from "c/tokenList";
import getTokensByAccount from "@salesforce/apex/TokenSelector.getTokensByAccount";

const MOCK_TOKENS = [
  {
    Id: "a001000000000001",
    Name: "TKN-000001",
    Status__c: "Active",
    Issued_Date__c: "2024-01-01",
    Expiry_Date__c: "2025-01-01",
    Scope__c: "read:all"
  },
  {
    Id: "a001000000000002",
    Name: "TKN-000002",
    Status__c: "Expired",
    Issued_Date__c: "2023-01-01",
    Expiry_Date__c: "2024-01-01",
    Scope__c: "read:write"
  },
  {
    Id: "a001000000000003",
    Name: "TKN-000003",
    Status__c: "Revoked",
    Issued_Date__c: "2023-06-01",
    Expiry_Date__c: "2024-06-01",
    Scope__c: "admin"
  }
];

describe("c-token-list", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders datatable when tokens are returned by wire", async () => {
    const element = createElement("c-token-list", { is: TokenList });
    element.recordId = "001000000000001AAA";
    document.body.appendChild(element);

    getTokensByAccount.emit(MOCK_TOKENS);
    await Promise.resolve();

    const datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable).not.toBeNull();
    expect(datatable.data.length).toBe(3);
  });

  it("shows error message when wire returns error", async () => {
    const element = createElement("c-token-list", { is: TokenList });
    element.recordId = "001000000000001AAA";
    document.body.appendChild(element);

    getTokensByAccount.emitError({ message: "Network error" });
    await Promise.resolve();

    const datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable).toBeNull();

    const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
    expect(errorDiv).not.toBeNull();
  });

  it("shows empty state message when no tokens are returned", async () => {
    const element = createElement("c-token-list", { is: TokenList });
    element.recordId = "001000000000001AAA";
    document.body.appendChild(element);

    getTokensByAccount.emit([]);
    await Promise.resolve();

    const datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable).toBeNull();

    const emptyState = element.shadowRoot.querySelector(
      ".slds-text-color_weak"
    );
    expect(emptyState).not.toBeNull();
  });

  it("maps Active status to success badge variant class", async () => {
    const element = createElement("c-token-list", { is: TokenList });
    element.recordId = "001000000000001AAA";
    document.body.appendChild(element);

    getTokensByAccount.emit(MOCK_TOKENS);
    await Promise.resolve();

    const datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable).not.toBeNull();
    const activeToken = datatable.data.find((t) => t.Status__c === "Active");
    expect(activeToken.statusClass).toBe("success");
  });

  it("maps Expired status to warning badge variant class", async () => {
    const element = createElement("c-token-list", { is: TokenList });
    element.recordId = "001000000000001AAA";
    document.body.appendChild(element);

    getTokensByAccount.emit(MOCK_TOKENS);
    await Promise.resolve();

    const datatable = element.shadowRoot.querySelector("lightning-datatable");
    const expiredToken = datatable.data.find((t) => t.Status__c === "Expired");
    expect(expiredToken.statusClass).toBe("warning");
  });

  it("maps Revoked status to error badge variant class", async () => {
    const element = createElement("c-token-list", { is: TokenList });
    element.recordId = "001000000000001AAA";
    document.body.appendChild(element);

    getTokensByAccount.emit(MOCK_TOKENS);
    await Promise.resolve();

    const datatable = element.shadowRoot.querySelector("lightning-datatable");
    const revokedToken = datatable.data.find((t) => t.Status__c === "Revoked");
    expect(revokedToken.statusClass).toBe("error");
  });
});
