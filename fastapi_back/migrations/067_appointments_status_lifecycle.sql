-- Expand legacy appointments.status check to match lifecycle service mappings.
-- Without this, BOOKED -> CONFIRMED transitions fail with appointments_status_check.

ALTER TABLE appointments DROP CONSTRAINT IF EXISTS appointments_status_check;

ALTER TABLE appointments ADD CONSTRAINT appointments_status_check
    CHECK (
        LOWER(COALESCE(status, 'pending')) IN (
            'pending',
            'confirmed',
            'in-queue',
            'in-consult',
            'completed',
            'no-show',
            'cancelled',
            'rescheduled',
            'expired',
            'refund-pending',
            'refunded',
            'followup-available',
            'followup-used',
            'followup-expired',
            'closed'
        )
    );
