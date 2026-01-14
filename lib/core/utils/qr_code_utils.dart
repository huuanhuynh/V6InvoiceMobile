class ExtractedQRCode {
  final String maVt;
  final String maViTri;
  final String maKho;
  final String identifier;

  const ExtractedQRCode({
    required this.maVt,
    required this.maViTri,
    required this.maKho,
    required this.identifier,
  });
}

/// Extracts parts from scanned QR code data.
/// Expected format: "maVt{sep}location{sep}warehouse{sep}identifier".
/// The default separator is `|`, but can be overridden via [separator].
/// Returns null if format is invalid.
ExtractedQRCode? extractScannedQRCode(
  String scannedData, {
  String separator = '|',
}) {
  final parts = scannedData.split(separator);
  if (parts.length != 4) return null;
  return ExtractedQRCode(
    maVt: parts[0],
    maViTri: parts[1],
    maKho: parts[2],
    identifier: parts[3],
  );
}
