// The phone's Power button (PhoneBody.qml) is pushed in while it is pressed, on the 2.5D phone
// (the stack of copies moves toward the wall) and on the 2D one (the flat button slides into the
// edge). The QML can't be run here, so the wiring is read from source. Run: node power_press_test.js
const fs = require('fs'), assert = require('assert')
const P = fs.readFileSync(__dirname + '/../../modules/sekai/phone/PhoneBody.qml', 'utf8')

// one press value, animated, held at least a moment so a quick tap still shows
assert.ok(/property real powerPress: root\.powerDown \? 1 : 0/.test(P), 'powerPress follows the press')
assert.ok(/readonly property bool powerDown: root\.powerHeld \|\| powerHoldTimer\.running/.test(P), 'a tap is held for a moment')
assert.ok(/Behavior on powerPress \{[\s\S]*?NumberAnimation/.test(P), 'and it is animated')
assert.ok(/Easing\.OutBack/.test(P.split('Behavior on powerPress')[1].slice(0, 300)), 'it springs back out')
const hold = +P.match(/id: powerHoldTimer\s*\n\s*interval: (\d+)/)[1]
assert.ok(hold >= 80 && hold <= 200, 'the hold is short (' + hold + ' ms)')

// 2.5D: only the Power button's copies take the shorter depth; the broad lower button does not
const stack = P.split('// The Power button\'s own copies')
assert.strictEqual(stack.length, 2, 'the power copies are their own repeater')
assert.ok(/root\.powerStickNow \/ root\.buttonSlices/.test(stack[1]), 'their depth is the pressed depth')
assert.ok(!/powerSlice/.test(stack[0]), 'the shared stack no longer holds the power button')
// The lower button's Repeater (the one using buttonStick / buttonSlices) must not
// use powerStickNow; extract that repeater from the pre-power-button section and
// check it there (powerStickNow is a component-level property, so it lives above).
const lowerRepeater = stack[0].match(/Repeater \{[\s\S]*?root\.buttonStick \/ root\.buttonSlices[\s\S]*?\}/)
assert.ok(lowerRepeater && !/powerStickNow/.test(lowerRepeater[0]), 'the lower button keeps its full depth')
const keep = +P.match(/powerKeep: ([\d.]+)/)[1]
assert.ok(keep > 0 && keep < 0.5, 'a little of the button stays out so its side shows')
assert.ok(/powerStickNow: root\.buttonStick \* \(1 - \(1 - root\.powerKeep\) \* root\.powerPress\)/.test(P))

// 2D: the button slides in and its underside closes up under it
const flat = P.split('Power button, phone facing straight on')[1].split('===== the front =====')[0]
assert.ok(/x: root\.faceWidth - 4 - root\.powerSlide \* root\.powerPress/.test(flat), 'it slides toward the body')
assert.ok(/y: root\.powerY \+ 5 \* \(1 - root\.powerPress\)/.test(flat), 'the underside closes up')

// both report the press, and the click area does not slide away from the pointer
assert.strictEqual((P.match(/root\.powerHeld = pressed/g) || []).length, 2, 'both areas set powerHeld')
assert.ok(/id: powerTabArea[\s\S]*?x: root\.faceWidth/.test(flat), '2D: the click area sits at the face edge')
// powerTab is a Rectangle that closes before its MouseArea starts: the click area is a sibling, not a child
const tabStart = flat.indexOf('id: powerTab')
const tabClose = flat.indexOf('\n                }', tabStart)
const mouseStart = flat.indexOf('MouseArea', tabClose)
assert.ok(tabClose > 0 && mouseStart > tabClose, '2D: the click area is not the sliding button\'s child')
console.log('power press: ok')
