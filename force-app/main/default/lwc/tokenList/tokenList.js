import { LightningElement, api, wire, track } from "lwc";
import getTokensByAccount from "@salesforce/apex/TokenSelector.getTokensByAccount";

const STATUS_VARIANT_MAP = {
  Active: "success",
  Expired: "warning",
  Revoked: "error"
};

const COLUMNS = [
  { label: "Name", fieldName: "Name", type: "text" },
  {
    label: "Status",
    fieldName: "Status__c",
    type: "text",
    cellAttributes: {
      class: { fieldName: "statusClass" }
    }
  },
  { label: "Issued Date", fieldName: "Issued_Date__c", type: "date" },
  { label: "Expiry Date", fieldName: "Expiry_Date__c", type: "date" },
  { label: "Scope", fieldName: "Scope__c", type: "text" }
];

export default class TokenList extends LightningElement {
  @api recordId;
  @track tokens = [];
  @track hasError = false;
  @track isLoading = true;

  columns = COLUMNS;

  @wire(getTokensByAccount, { accountId: "$recordId" })
  wiredTokens({ error, data }) {
    this.isLoading = false;
    if (data) {
      this.tokens = data.map((token) => ({
        ...token,
        statusClass: this._badgeVariantClass(token.Status__c)
      }));
      this.hasError = false;
    } else if (error) {
      this.tokens = [];
      this.hasError = true;
    }
  }

  get hasTokens() {
    return this.tokens && this.tokens.length > 0;
  }

  _badgeVariantClass(status) {
    return STATUS_VARIANT_MAP[status] || "default";
  }
}
