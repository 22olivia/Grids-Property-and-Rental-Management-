import { NextResponse } from 'next/server';
import { httpAssetRepository } from '@/features/ast/api/http-asset-repository';
import { requireToken, toErrorResponse } from '@/lib/api/bff';
import { withToken } from '@/lib/api/with-token';

export async function GET(_request: Request, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireToken();
  if ('response' in auth) return auth.response;
  const { id } = await params;
  try {
    return NextResponse.json(await withToken(auth.token, () => httpAssetRepository.getUnit(id)));
  } catch (error) {
    return toErrorResponse(error);
  }
}

export async function PUT(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireToken();
  if ('response' in auth) return auth.response;
  const { id } = await params;
  try {
    const body = await request.json();
    return NextResponse.json(
      await withToken(auth.token, () => httpAssetRepository.updateUnit(id, body)),
    );
  } catch (error) {
    return toErrorResponse(error);
  }
}

export async function DELETE(_request: Request, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireToken();
  if ('response' in auth) return auth.response;
  const { id } = await params;
  try {
    await withToken(auth.token, () => httpAssetRepository.deleteUnit(id));
    // 204: the backend returns only a message, and there is nothing the UI
    // needs from a successful delete beyond the status.
    return new NextResponse(null, { status: 204 });
  } catch (error) {
    return toErrorResponse(error);
  }
}
