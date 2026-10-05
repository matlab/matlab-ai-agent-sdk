function throwError(messageId, hole)
%throwError Throw an error described by a message catalog entry.
%   throwError(MESSAGEID) throws an error with identifier MESSAGEID and the
%   catalog message stored under the same key.
%
%   throwError(MESSAGEID, HOLE1, HOLE2, ...) fills the "{n}" placeholders in
%   the catalog message before throwing.

%   Copyright 2026 The MathWorks, Inc.

    arguments
        messageId {mustBeNonzeroLengthText}
    end
    arguments(Repeating)
        hole {mustBeTextScalar}
    end

    msg = aisdk.internal.MessageCatalog.getMessage(messageId, hole{:});
    % The "%s" keeps a "%" or "\" in the message, or in a hole holding server
    % output or user data, from being read as a format specifier.
    throwAsCaller(MException(messageId, "%s", msg));
end
