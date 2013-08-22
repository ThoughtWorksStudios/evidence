module Evidence
  def rails2_action_patterns
    {
      start: /^
          (\#012\#012)?             # ignore encoded newlines
          Processing\s+
          (?<controller>\w+)\#(?<action>\w+)\s+
          \(for\s+
          (?<remote_addr>[^\s]+)\s+
          at\s+
          (?<timestamp>[^\)]+)\)\s+
          \[(?<method>[\w]+)\]
        $/x,
      end: /^
          Completed\sin\s
          (?<completed_time>\d+)ms\s+
          \((View\:\s(?<view_time>\d+))?
          \s*,?\s*
          (\s*DB\:\s(?<db_time>\d+))?
          \)\s+\|\s+
          (?<code>\d+)\s+
          (?<status>\w+)\s+
          \[(?<url>.+)\]
        $/x
    }
  end
end
