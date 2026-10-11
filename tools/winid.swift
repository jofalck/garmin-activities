import CoreGraphics
let l = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as! [[String: Any]]
for w in l where (w["kCGWindowOwnerName"] as? String ?? "").lowercased().contains("simulator") {
  print(w["kCGWindowNumber"]!, w["kCGWindowName"] ?? "", w["kCGWindowBounds"]!)
}
