# Generated API types

**This directory is generated output. Do not hand-edit files here.**

It is empty because the GPMS API contract has not been published. Backlog
story `US-API-006` ("Publish OpenAPI documentation and maintain a Postman
collection") is scheduled for **Sprint 12**.

SRS §12 contains a table headed *"Example Endpoints"* — ten domain groups with
paths only, carrying no methods, schemas, field names, status codes or filter
grammar. It is a grouping, not a contract, and nothing has been generated from
it.

## Interim approach

Until the spec lands, request and response shapes are declared as Zod schemas
inside the feature that needs them, marked `@provisional`, and published to the
backend team as proposals rather than assumptions.

## When the spec is published

Generate types into this directory and delete the provisional schemas. Every
divergence between what the frontend assumed and what the API actually returns
then surfaces as a **compile error** rather than a runtime surprise — which is
the entire reason for doing it this way round.
