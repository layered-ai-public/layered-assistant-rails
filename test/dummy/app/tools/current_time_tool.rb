# A tool with no arguments, available to public assistants as well as
# signed-in ones because it reaches nothing owned by anybody.
class CurrentTimeTool < Layered::Assistant::Tool
  description "Get the current date and time on the server."
  requires_owner false

  argument :time_zone, :string, description: "An IANA time zone name, e.g. 'Europe/London'. Defaults to UTC."

  def call(time_zone: "UTC")
    zone = ActiveSupport::TimeZone[time_zone] or raise "Unknown time zone: #{time_zone}"

    { time: zone.now.iso8601, time_zone: zone.name }
  end
end
