locals {

  aurora_mysql_zerotetl_parameters = {
    aurora_enhanced_binlog = {
      value        = "1"
      apply_method = "pending-reboot"
    }
    binlog_backup = {
      value        = "0"
      apply_method = "pending-reboot"
    }
    binlog_format = {
      value        = "ROW"
      apply_method = "pending-reboot"
    }
    binlog_replication_globaldb = {
      value        = "0"
      apply_method = "pending-reboot"
    }
    binlog_row_image = {
      value        = "full"
      apply_method = "pending-reboot"
    }
    binlog_row_metadata = {
      value        = "full"
      apply_method = "pending-reboot"
    }
    binlog_transaction_compression = {
      value        = "OFF"
      apply_method = "pending-reboot"
    }
    binlog_row_value_options = {
      value        = ""
      apply_method = "pending-reboot"
    }
    log_bin_trust_function_creators = {
      value        = "1"
      apply_method = "pending-reboot"
    }
  }
}
