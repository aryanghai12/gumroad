# frozen_string_literal: true

require "spec_helper"

RSpec.describe Purchase, type: :model do
  describe "VAT ID storage and persistence for renewals" do
    before do
      create(:zip_tax_rate, country: "IT", zip_code: nil, state: nil, combined_rate: 0.22, is_seller_responsible: false)

      @product = create(:subscription_product, price_cents: 1000)
      @user = create(:user, credit_card: create(:credit_card))
      @subscription = create(:subscription, user: @user, link: @product)
    end

    context "when VAT ID is added via refund_gumroad_taxes!" do
      it "validates and stores VAT ID in purchase_sales_tax_info for future use", :vcr do
        original_purchase = create(
          :purchase,
          is_original_subscription_purchase: true,
          link: @product,
          subscription: @subscription,
          chargeable: build(:chargeable),
          purchase_state: "in_progress",
          full_name: "Mario Rossi",
          ip_address: "2.47.255.255",
          country: "Italy",
          created_at: 2.days.ago
        )

        original_purchase.process!(off_session: false)
        expect(original_purchase.reload.gumroad_tax_cents).to eq 220
        expect(original_purchase.purchase_sales_tax_info.business_vat_id).to be_nil

        vat_id = "IT12345678901"
        result = original_purchase.refund_gumroad_taxes!(
          refunding_user_id: @product.user.id,
          note: "Customer provided VAT ID",
          business_vat_id: vat_id
        )

        expect(result).to be true

        original_purchase.reload
        expect(original_purchase.purchase_sales_tax_info.business_vat_id).to eq vat_id

        latest_refund = original_purchase.refunds.last
        expect(latest_refund.business_vat_id).to eq vat_id
        expect(latest_refund.gumroad_tax_cents).to eq 220
      end

      it "does not store VAT ID if validation fails" do
        original_purchase = create(
          :purchase,
          is_original_subscription_purchase: true,
          link: @product,
          subscription: @subscription,
          chargeable: build(:chargeable),
          purchase_state: "successful",
          full_name: "Mario Rossi",
          ip_address: "2.47.255.255",
          country: "Italy",
          gumroad_tax_cents: 220
        )

        invalid_vat_id = "INVALID123"
        original_purchase.refund_gumroad_taxes!(
          refunding_user_id: @product.user.id,
          note: "Invalid VAT ID provided",
          business_vat_id: invalid_vat_id
        )

        original_purchase.reload
        expect(original_purchase.purchase_sales_tax_info.business_vat_id).to be_nil

        latest_refund = original_purchase.refunds.last
        expect(latest_refund.business_vat_id).to eq invalid_vat_id
      end
    end

    context "when VAT ID was validated and stored on original purchase" do
      it "reuses stored VAT ID on renewals without re-validation", :vcr do
        vat_id = "IT12345678901"
        original_purchase = create(
          :purchase,
          is_original_subscription_purchase: true,
          link: @product,
          subscription: @subscription,
          chargeable: build(:chargeable),
          purchase_state: "in_progress",
          full_name: "Mario Rossi",
          business_vat_id: vat_id,
          ip_address: "2.47.255.255",
          country: "Italy",
          created_at: 2.days.ago
        )

        original_purchase.process!(off_session: false)
        expect(original_purchase.reload.gumroad_tax_cents).to eq 0
        expect(original_purchase.purchase_sales_tax_info.business_vat_id).to eq vat_id

        allow_any_instance_of(VatValidationService).to receive(:process).and_return(false)

        @subscription.charge!
        renewal_purchase = @subscription.reload.purchases.last

        expect(renewal_purchase.purchase_state).to eq "successful"
        expect(renewal_purchase.purchase_sales_tax_info.business_vat_id).to eq vat_id
        expect(renewal_purchase.gumroad_tax_cents).to eq 0
      end

      it "transfers VAT ID from refund to renewal when stored in purchase_sales_tax_info", :vcr do
        original_purchase = create(
          :purchase,
          is_original_subscription_purchase: true,
          link: @product,
          subscription: @subscription,
          chargeable: build(:chargeable),
          purchase_state: "in_progress",
          full_name: "Mario Rossi",
          ip_address: "2.47.255.255",
          country: "Italy",
          created_at: 2.days.ago
        )

        original_purchase.process!(off_session: false)
        expect(original_purchase.reload.gumroad_tax_cents).to eq 220

        vat_id = "IT12345678901"
        original_purchase.refund_gumroad_taxes!(
          refunding_user_id: @product.user.id,
          note: "Customer provided VAT ID",
          business_vat_id: vat_id
        )

        expect(original_purchase.reload.purchase_sales_tax_info.business_vat_id).to eq vat_id

        allow_any_instance_of(VatValidationService).to receive(:process).and_return(false)

        @subscription.charge!
        renewal_purchase = @subscription.reload.purchases.last

        expect(renewal_purchase.purchase_state).to eq "successful"
        expect(renewal_purchase.purchase_sales_tax_info.business_vat_id).to eq vat_id
        expect(renewal_purchase.gumroad_tax_cents).to eq 0
      end
    end

    context "when purchase is NOT a renewal" do
      it "still requires strict VAT ID validation for new purchases" do
        allow_any_instance_of(VatValidationService).to receive(:process).and_return(false)

        new_purchase = create(
          :purchase,
          link: @product,
          chargeable: build(:chargeable),
          purchase_state: "in_progress",
          full_name: "Mario Rossi",
          business_vat_id: "IT12345678901",
          ip_address: "2.47.255.255",
          country: "Italy"
        )

        new_purchase.process!(off_session: false)
        new_purchase.reload

        expect(new_purchase.gumroad_tax_cents).to eq 220
        expect(new_purchase.purchase_sales_tax_info.business_vat_id).to be_nil
      end
    end
  end
end
