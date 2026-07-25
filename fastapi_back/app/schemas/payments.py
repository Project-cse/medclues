from pydantic import BaseModel, Field, model_validator


class CreateOrderRequest(BaseModel):
    amount: float | None = Field(default=None, ge=0)
    doctor_id: str | int | None = None
    currency: str = Field(default="INR", max_length=8)
    receipt: str | None = Field(default=None, max_length=64)
    appointment_date: str | None = None
    appointment_time: str | None = None
    visit_type: str | None = None
    mode: str | None = None
    notes: str | None = Field(default=None, max_length=500)
    slot_id: int | str | None = None
    slot_type: str | None = None

    @model_validator(mode="after")
    def require_amount_or_doctor(self):
        if self.doctor_id is None and self.amount is None:
            raise ValueError("amount is required (INR or paise)")
        return self
