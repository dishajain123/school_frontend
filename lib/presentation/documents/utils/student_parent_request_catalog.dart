// Merges admin-mandated document requirements with school-issued / requestable types
// for the student & parent "Request document" flow.

import '../../../data/models/document/document_model.dart';

/// Default request options (logical order). Deduped with admin requirements.
/// Fee line uses [DocumentType.other] + note because the backend has no separate fee type.
const List<RequiredDocumentModel> schoolIssuedRequestPresets = [
  RequiredDocumentModel(documentType: DocumentType.bonafide),
  RequiredDocumentModel(documentType: DocumentType.idCard),
  RequiredDocumentModel(documentType: DocumentType.reportCard),
  RequiredDocumentModel(documentType: DocumentType.transferCertificate),
  RequiredDocumentModel(
    documentType: DocumentType.other,
    note: 'Fee Receipt / Fee Statement',
  ),
  RequiredDocumentModel(documentType: DocumentType.other),
];

/// Admin-configured requirements first, then default school-issued options (deduped).
List<RequiredDocumentModel> buildStudentParentRequestCatalog(
  List<RequiredDocumentModel> adminRequirements,
) {
  final merged = <RequiredDocumentModel>[];
  final seen = <String>{};

  void add(RequiredDocumentModel r) {
    final key = r.documentType == DocumentType.other
        ? 'OTHER|${(r.note ?? '').trim()}'
        : r.documentType.backendValue;
    if (seen.add(key)) merged.add(r);
  }

  for (final r in adminRequirements) {
    add(r);
  }
  for (final preset in schoolIssuedRequestPresets) {
    add(preset);
  }
  return merged;
}
