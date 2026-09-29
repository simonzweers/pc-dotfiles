pragma Singleton
// SystemStats.qml
// polls /proc for CPU and memory usage

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root
  property real cpuUsage: 0 // percent
  property real memUsage: 0 // percent
  property real memUsedGb: 0

  property var lastCpu: null

  FileView {
    id: stat
    path: "/proc/stat"
    onLoaded: {
      // first line: "cpu user nice system idle iowait irq softirq steal ..."
      const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
      const idle = f[3] + f[4]
      const total = f.reduce((a, b) => a + b, 0)
      if (root.lastCpu && total > root.lastCpu.total)
        root.cpuUsage = 100 * (1 - (idle - root.lastCpu.idle) / (total - root.lastCpu.total))
      root.lastCpu = { idle, total }
    }
  }

  FileView {
    id: meminfo
    path: "/proc/meminfo"
    onLoaded: {
      const kb = key => Number(text().match(new RegExp(key + ":\\s+(\\d+)"))[1])
      const total = kb("MemTotal")
      const used = total - kb("MemAvailable")
      root.memUsage = 100 * used / total
      root.memUsedGb = used / 1024 / 1024
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      stat.reload()
      meminfo.reload()
    }
  }
}
