CREATE TABLE "users" ("user_id" UUID PRIMARY KEY, "email" TEXT NOT NULL, "phone" TEXT NOT NULL, "display_name" TEXT, "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP, "last_login_at" TIMESTAMPTZ);
CREATE UNIQUE INDEX "users_email_phone_key" ON "users"("email", "phone");
CREATE TABLE "auth_sessions" ("session_id" UUID PRIMARY KEY, "user_id" UUID NOT NULL REFERENCES "users"("user_id"), "token_hash" TEXT NOT NULL UNIQUE, "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP, "revoked_at" TIMESTAMPTZ);
CREATE INDEX "auth_sessions_user_id_idx" ON "auth_sessions"("user_id");
CREATE TABLE "meters" ("meter_id" TEXT PRIMARY KEY, "external_status" TEXT NOT NULL, "external_snapshot" JSONB, "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP, "updated_at" TIMESTAMPTZ NOT NULL);
CREATE TABLE "verification_cases" ("case_id" UUID PRIMARY KEY, "meter_id" TEXT NOT NULL REFERENCES "meters"("meter_id"), "user_id" UUID NOT NULL REFERENCES "users"("user_id"), "status" TEXT NOT NULL, "overall_verdict" TEXT, "report_version" INTEGER NOT NULL, "checksum" TEXT, "payload" JSONB NOT NULL, "created_at" TIMESTAMPTZ NOT NULL, "closed_at" TIMESTAMPTZ, "updated_at" TIMESTAMPTZ NOT NULL);
CREATE INDEX "verification_cases_meter_id_status_idx" ON "verification_cases"("meter_id", "status");
CREATE INDEX "verification_cases_user_id_created_at_idx" ON "verification_cases"("user_id", "created_at");
CREATE TABLE "flow_points" ("flow_point_id" UUID PRIMARY KEY, "case_id" UUID NOT NULL REFERENCES "verification_cases"("case_id"), "code" TEXT NOT NULL, "status" TEXT NOT NULL, "checksum" TEXT, "payload" JSONB NOT NULL, "created_at" TIMESTAMPTZ NOT NULL, "updated_at" TIMESTAMPTZ NOT NULL);
CREATE UNIQUE INDEX "flow_points_case_id_code_key" ON "flow_points"("case_id", "code");
CREATE TABLE "samples" ("sample_id" UUID PRIMARY KEY, "flow_point_id" UUID NOT NULL REFERENCES "flow_points"("flow_point_id"), "sample_number" INTEGER NOT NULL, "status" TEXT NOT NULL, "checksum" TEXT NOT NULL, "payload" JSONB NOT NULL, "started_at" TIMESTAMPTZ, "ended_at" TIMESTAMPTZ, "created_at" TIMESTAMPTZ NOT NULL);
CREATE INDEX "samples_flow_point_id_sample_number_idx" ON "samples"("flow_point_id", "sample_number");
CREATE TABLE "evidence" ("evidence_id" UUID PRIMARY KEY, "sample_id" UUID REFERENCES "samples"("sample_id"), "pending_sample_id" UUID, "sha256" TEXT NOT NULL, "storage_key" TEXT NOT NULL, "original_filename" TEXT, "mime_type" TEXT NOT NULL, "size_bytes" INTEGER NOT NULL, "payload" JSONB NOT NULL, "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE UNIQUE INDEX "evidence_sha256_storage_key_key" ON "evidence"("sha256", "storage_key");
CREATE INDEX "evidence_sample_id_idx" ON "evidence"("sample_id");
CREATE INDEX "evidence_pending_sample_id_idx" ON "evidence"("pending_sample_id");
CREATE TABLE "reports" ("report_id" UUID PRIMARY KEY, "case_id" UUID NOT NULL REFERENCES "verification_cases"("case_id"), "version" INTEGER NOT NULL, "checksum" TEXT NOT NULL, "html_key" TEXT, "pdf_key" TEXT, "payload" JSONB NOT NULL, "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE INDEX "reports_case_id_version_idx" ON "reports"("case_id", "version");
CREATE TABLE "deployment_metadata" ("key" TEXT PRIMARY KEY, "value" TEXT NOT NULL, "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP);
INSERT INTO "deployment_metadata" ("key", "value") VALUES
  ('database_schema_version', '1'),
  ('api_contract_version', 'v1'),
  ('sync_contract_version', 'v1');
