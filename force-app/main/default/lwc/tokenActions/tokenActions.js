import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import issueTokenAura from "@salesforce/apex/TokenService.issueTokenAura";
import revokeTokenAura from "@salesforce/apex/TokenService.revokeTokenAura";

export default class TokenActions extends LightningElement {
  @api recordId;
  @api selectedTokenId;

  @track scope = "";
  @track expiryDate = "";

  get isRevokeDisabled() {
    return !this.selectedTokenId;
  }

  handleScopeChange(event) {
    this.scope = event.target.value;
  }

  handleExpiryChange(event) {
    this.expiryDate = event.target.value;
  }

  handleIssueToken() {
    if (!this.scope || !this.expiryDate) {
      this._showToast(
        "Validation Error",
        "Scope and Expiry Date are required.",
        "error"
      );
      return;
    }
    issueTokenAura({
      accountId: this.recordId,
      expiryDateStr: this.expiryDate,
      scope: this.scope
    })
      .then(() => {
        this._showToast("Success", "Token issued successfully.", "success");
        this._fireRefresh();
        this.scope = "";
        this.expiryDate = "";
      })
      .catch((error) => {
        this._showToast("Error", this._extractMessage(error), "error");
      });
  }

  handleRevokeToken() {
    revokeTokenAura({ tokenId: this.selectedTokenId })
      .then(() => {
        this._showToast("Success", "Token revoked successfully.", "success");
        this._fireRefresh();
      })
      .catch((error) => {
        this._showToast("Error", this._extractMessage(error), "error");
      });
  }

  _showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  _fireRefresh() {
    this.dispatchEvent(new CustomEvent("tokenrefresh"));
  }

  _extractMessage(error) {
    if (error && error.body && error.body.message) {
      return error.body.message;
    }
    return "An unexpected error occurred.";
  }
}
