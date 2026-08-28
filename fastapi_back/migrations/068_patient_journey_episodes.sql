-- Persist closed care-journey episodes for Past My Journey history.

CREATE TABLE IF NOT EXISTS patient_journey_episodes (
    id              BIGSERIAL PRIMARY KEY,
    patient_id      INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    appointment_id  INTEGER NOT NULL UNIQUE,
    episode_label   TEXT,
    journey_status  VARCHAR(32),
    payload         JSONB NOT NULL DEFAULT '{}'::jsonb,
    closed_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_patient_journey_episodes_patient
    ON patient_journey_episodes (patient_id, closed_at DESC);
