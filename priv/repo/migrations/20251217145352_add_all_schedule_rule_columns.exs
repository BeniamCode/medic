defmodule Medic.Repo.Migrations.AddAllScheduleRuleColumns do
  use Ecto.Migration

  def change do
    alter table(:schedule_rules) do
      # Timing columns
      add_if_not_exists :work_start_local, :time
      add_if_not_exists :work_end_local, :time
      add_if_not_exists :slot_interval_minutes, :integer, default: 30
      add_if_not_exists :buffer_before_minutes, :integer, default: 0
      add_if_not_exists :buffer_after_minutes, :integer, default: 0
      
      # Metadata
      add_if_not_exists :label, :string
      add_if_not_exists :priority, :integer, default: 0
      
      # Scoping - just add the columns, FK constraints already exist
      add_if_not_exists :scope_consultation_mode, :string
      add_if_not_exists :scope_appointment_type_id, :uuid
      add_if_not_exists :scope_doctor_location_id, :uuid
      add_if_not_exists :scope_location_room_id, :uuid
      
      # Validity period
      add_if_not_exists :effective_from, :date
      add_if_not_exists :effective_to, :date
    end
  end
end
