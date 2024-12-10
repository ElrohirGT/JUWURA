{
  working_dir = "./backend";
  command = "zig build run";
  ready_log_line = "Listening on";
  depends_on = {
    database.condition = "process_log_ready";
  };
}
