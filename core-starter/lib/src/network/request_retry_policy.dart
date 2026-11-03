/// Transient transport retries are only safe for operations without side effects.
/// A GET endpoint that changes data must explicitly select [never].
enum RequestRetryPolicy { readOnly, never }
