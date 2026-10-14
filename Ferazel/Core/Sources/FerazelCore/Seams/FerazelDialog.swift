import Foundation

/// A modal dialog the original runs with the Dialog Manager (plan S3, FE0; LOCKED); the App draws it from the DLOG/DITL
/// (`DialogResources`) and answers through `GameFlow.dialogDone`.
public enum FerazelDialog: Equatable, Sendable {
    /// DLOG 202: the confirm question (OK / Cancel).
    case confirm(text: String)
    /// DLOG 200: a report with OK.
    case report(text: String)
    /// An error report with its OSErr-style code.
    case error(text: String, code: Int16)
    /// DLOG 6900: the Options dialog — no payload: the flow owns O1's `PrefsDialogModel` and the App reads it there.
    case preferences
    /// The credits screen.
    case credits
}
