package com.ssafy.b205.backend.infra.docs;

public final class DocRefs {
    public static final String BAD_REQUEST  = "#/components/responses/BadRequestError";
    public static final String UNAUTHORIZED = "#/components/responses/UnauthorizedError";
    public static final String FORBIDDEN    = "#/components/responses/ForbiddenError";
    public static final String NOT_FOUND    = "#/components/responses/NotFoundError";
    public static final String CONFLICT     = "#/components/responses/ConflictError";
    public static final String METHOD_NOT_ALLOWED = "#/components/responses/MethodNotAllowedError";
    public static final String INTERNAL     = "#/components/responses/InternalServerError";
    private DocRefs() {}
}
