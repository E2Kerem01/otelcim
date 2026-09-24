// Reads the newest SMS code the Firebase Auth emulator "sent" (runs on the
// host, so 127.0.0.1 is the emulator). Optional env PHONE (+905550000001)
// picks that number's latest code. Result: output.smsCode
var res = http.get('http://127.0.0.1:9099/emulator/v1/projects/otelcim-7f0ba/verificationCodes');
var codes = json(res.body).verificationCodes || [];
if (typeof PHONE !== 'undefined' && PHONE) {
  codes = codes.filter(function (c) { return c.phoneNumber === PHONE; });
}
if (codes.length === 0) throw new Error('no SMS code in the Auth emulator');
output.smsCode = codes[codes.length - 1].code;
