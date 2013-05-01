
#include <Servo.h>
#include <SoftwareSerial.h>

// ピン番号定義
#define realIn1 5   // モータードライバ1
#define realIn2 4   // モータードライバ2
#define servoPin 10  // サーボモータ
#define blePin1 3   // Bluetooth 1
#define blePin2 2   // Bluetooth 2

#define gyroX A1    // ジャイロセンサ(使ってない)
#define gyroY A2    // ジャイロセンサ(使ってない)


// Bluetoothモジュールからの命令文字.
#define CASE_POLE 'p'
#define CASE_REEL_IN 'i'
#define CASE_REEL_OUT 'o'
#define CASE_REEL_STOP 's'
#define CASE_WAITTING 'w'
#define CASE_POLE_STOP 'a'
#define CASE_PULL 'b'

#define CASE_POLE_PATTERN_NORMAL 'x'
#define CASE_POLE_PATTERN_LONG 'y'
#define CASE_POLE_PATTERN_AORI 'z'
#define CASE_POLE_PATTERN_FULL 'f'


// ステート.
typedef enum TEST_STATE {
    STATE_STOP = 0,
    STATE_REAL_FORWARD,
    STATE_REAL_BACKWARD,
    STATE_SERVO,
    STATE_HIT_CHECK,
    
}TestState;

Servo servo;
static long beforeTime = 0;
float currentServoDegree = 70;

TestState tstate = STATE_STOP;

// Bluetoothを動かすようのシリアルセット.
SoftwareSerial bleShield(blePin1, blePin2);


// セットアップ(1回のみ呼ばれる)
void setup() {
    servo.attach(servoPin); //サーボ
    // モータードライバセットアップ.
    pinMode(realIn1, INPUT);
    pinMode(realIn2, INPUT);
    
    
    beforeTime = millis();  //時間取得.
    // シリアル通信スタート.
    bleShield.begin(19200);
    Serial.begin(19200);
}

// ループ
// hardwareからずっと呼び続ける
void loop() {
    // 差分時間の計算
    int dt = millis() - beforeTime;
    beforeTime = millis();
    
    // iPhoneからの入力
    // ここでBluetoothの値を受け取ってステートを変える
    // USBで接続する場合はここをうまい事ください。
    if (bleShield.available()) {
        int value = bleShield.read();
        Serial.println(value);
        switch(value) {
            case CASE_REEL_IN:
                tstate = STATE_REAL_BACKWARD;
                break;
            case CASE_REEL_OUT:
                tstate = STATE_REAL_FORWARD;
                break;
            case CASE_REEL_STOP:
                tstate = STATE_STOP;
                break;
            case CASE_POLE_STOP:
                tstate = STATE_STOP;
                break;
            case CASE_POLE:
                tstate = STATE_SERVO;
                break;
            case CASE_PULL:
                break;
            case CASE_WAITTING:
                break;
        }
    }
    
    
    // 状態に応じた制御.
    switch (tstate) {
        case STATE_REAL_FORWARD:    // リールを送る
            initServo();
            startReal(true);
            break;
        case STATE_REAL_BACKWARD:   // リールを巻く
            initServo();
            startReal(false);
            break;
        case STATE_SERVO:   // 竿制御
            Serial.println("servo");
            stopReal();
            rodMove(dt, false);
            break;
        case STATE_HIT_CHECK:   // 当たり判定
            judgeHitLoop(dt);
            break;
            
        default:    // なにも無ければリールを止めてサーボを止める.
            stopReal();
            initServo();
            break;
    }

    
    servo.write(currentServoDegree);
    
   // ループの遅延設定
    // デバッグ時に必要であればここを増やして細かく確認.
    delay(1);
}



// リール制御.
void startReal(bool forward) {
    if(forward) {
        digitalWrite(realIn1, HIGH);
        digitalWrite(realIn2, LOW);
    }else {
        digitalWrite(realIn1, LOW);
        digitalWrite(realIn2, HIGH);
    }
}

// リールストップ.
void stopReal() {
    digitalWrite(realIn1, LOW);
    digitalWrite(realIn2, LOW);
}

// サーボの初期位置設定.
void initServo() {
    currentServoDegree = 70;
}

// 竿を動かす制御.
// car引数は使ってないです.
bool rodMove(int dt, bool car) {
    // 実際に動かすところ.
    bool finished = rodMove1(dt);
    
    if(finished) {
        tstate = STATE_HIT_CHECK;
    }

    return false;
}

float averageCaribratedX = 0;
float averageCaribratedY = 0;

static int judgeLimitTime = 3000;
static int judgeTime = 0;
int hcountx = 0;
int hcounty = 0;
bool firstHit = true;
int hitCount = 0;


// 当たり判定.
void judgeHitLoop(int dt) {
    judgeTime += dt;
    
    // 竿の動作が終わって３秒(judgeLimitTIme)待機、その後また動かす.
    if(judgeTime > judgeLimitTime) {
        
        tstate = STATE_SERVO;
        hcountx = 0;
        hcounty = 0;
        judgeTime = 0;
        hitCount = 0;
        firstHit = true;
    }
    return;
    //　デモ用にここから先は使ってない.
    
    
    float x = analogRead(gyroX) /10.0;
    float y = analogRead(gyroY) /10.0;
    Serial.print("x=");
    Serial.println(x);
    Serial.print("y=");
    Serial.println(y);
    
    float dx = averageCaribratedX - x;
    float dy = averageCaribratedX - y;
    if(abs(dx) > 10) {
        hcountx++;
    }
    if(abs(dy) > 10) {
        hcounty++;
    }
    
    if(hcountx > 200) {
        if(firstHit) {
            Serial.println("first hit");
            hitCount = 1;
            firstHit = false;
            tstate = STATE_STOP;
        }else {
            Serial.println("hit");
            hitCount++;
            if(hitCount > 3) {
                Serial.println("auto");
                tstate = STATE_STOP;
            }
        }
        
        judgeTime = 0;
        hcountx = 0;
        hcounty = 0;
    }
    
}


float rodMoveTime = 0;
int move1State = 0;
float beforeDeg = 70;
float opeDegree = 70;

// 竿の細かい制御動作
// timeArray1とdegArray1で時間と角度が同期している。
// 最後まで行くと１セット.
float timeArray1[] = {600, 1500, 600, 1500, 300, 2000};
float degArray1[] = {30, 70, 30, 70, 30, 70};

// 竿を動かす制御
bool rodMove1(int dt) {
    
    if(move1State == -1) {
        move1State = 0;
        beforeDeg = degArray1[0];
        rodMoveTime = 0;
    }
    
    rodMoveTime += dt;
    
    float dest = degArray1[move1State] - beforeDeg;
    float r1 = 3.14159 / 2.0;
    float k = r1 / (timeArray1[move1State] * 0.5) ;
    float deg2 = dest * sin(k * rodMoveTime);
    
    opeDegree = beforeDeg + deg2;
    if(dest < 0) {
        if(opeDegree <= degArray1[move1State]+0.1) {
            opeDegree = degArray1[move1State];
            rodMoveTime = 0;
            move1State++;
            beforeDeg = opeDegree;
        }
    }else {
        if(opeDegree >= degArray1[move1State] - 0.1) {
            opeDegree = degArray1[move1State];
            rodMoveTime = 0;
            move1State++;
            beforeDeg = opeDegree;
        }
    }
    
    currentServoDegree = (int)opeDegree;
    
    if(move1State == 6) {
        rodMoveTime = 0;
        move1State = 0;
        return true;
    }
    
    return false;
    
}









































