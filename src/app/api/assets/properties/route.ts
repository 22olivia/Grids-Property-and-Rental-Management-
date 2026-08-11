import { NextResponse } from 'next/server';
import { httpAssetRepository } from '@/features/ast/api/http-asset-repository';
import { readListQuery, requireToken, toErrorResponse } from '@/lib/api/bff';
import { withToken } from '@/lib/api/with-token';

export async function GET(request: Request) {
  const auth = await requireToken();
  if ('response' in auth) return auth.response;
  try {
    return NextResponse.json(
      await withToken(auth.token, () => httpAssetRepository.listProperties(readListQuery(request))),
    );
  } catch (error) {
    return toErrorResponse(error);
  }
}

export async function POST(request: Request) {
  const auth = await requireToken();
  if ('response' in auth) return auth.response;
  try {
    const body = await request.json();
    return NextResponse.json(
      await withToken(auth.token, () => httpAssetRepository.createProperty(body)),
      { status: 201 },
    );
  } catch (error) {
    return toErrorResponse(error);
  }
}
