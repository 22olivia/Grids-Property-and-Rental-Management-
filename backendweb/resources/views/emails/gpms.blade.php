<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>{{ $subject ?? 'GPMS' }}</title>
</head>
<body style="margin:0;padding:0;background:#f4f7f6;font-family:Georgia,'Times New Roman',serif;color:#16332f;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f4f7f6;padding:24px 12px;">
    <tr>
        <td align="center">
            <table role="presentation" width="100%" style="max-width:640px;background:#ffffff;border:1px solid #d7e3df;border-radius:16px;overflow:hidden;">
                <tr>
                    <td style="background:linear-gradient(135deg,#0f766e,#134e4a);color:#ffffff;padding:22px 28px;">
                        <div style="font-size:13px;letter-spacing:.08em;text-transform:uppercase;opacity:.85;">Grids Property Management System</div>
                        <div style="font-size:24px;font-weight:700;margin-top:6px;">{{ $heading ?? 'GPMS Notice' }}</div>
                    </td>
                </tr>
                <tr>
                    <td style="padding:28px;font-size:15px;line-height:1.65;color:#234741;">
                        {!! $bodyHtml !!}
                    </td>
                </tr>
                <tr>
                    <td style="padding:0 28px 28px;font-size:12px;color:#6b7f7a;">
                        This message was sent by GPMS. Do not share one-time codes with anyone.
                    </td>
                </tr>
            </table>
        </td>
    </tr>
</table>
</body>
</html>
