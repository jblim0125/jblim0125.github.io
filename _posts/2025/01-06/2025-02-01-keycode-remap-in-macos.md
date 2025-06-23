---
layout: post
title: 맥OS에서 키보드 입력 값 변경하기
author: jblim0125
date: 2025-02-01
category: 2025
---

## 개요

알리에서 판매하는 키보드를 구매했는데 맥환경에서 F1~12 키에 대해서 설정을 변경해도 특수 기능(media control)로 동작하여 본 포스팅을 작성하게 되었다.
특히나 키보드 입력을 변경해주는 대표적인 프로그램(카라비너?)를 사용해도 키보드 f3의 'mission_control'을 해제할 수 없었다.
그래서 로우레벨에서 키 입력을 인터셉트하여 변경하는 프로그램을 작성하였다.

해결 과정은 다음과 같다.

1. 키보드 정보
2. 입력 값 확인
3. 입력 값 변경
4. 테스트
5. 부팅 시 자동실행 설정

## 1. 키보드 정보

> 중요 : USB, 블루투스, 2.4G무선 중 하나에 연결된 상태에서 정보를 확인해야 한다.

- Bluetooth

```shell
$ system_profiler SPBluetoothDataType

Bluetooth:

      Bluetooth Controller:
          Vendor ID: 0x004C (Apple)
      Connected:
          xxx keyboard model:
              Vendor ID: 
              Product ID: 
          xxxx의 마우스:
              Vendor ID: 0x004C
              Product ID: 0x0269
      Not Connected:
          xxx iPhone:
          xxx’s MacBook Pro:
          xxx의 AirPods:
```

- USB

```shell
$ system_profiler SPUSBDataType

USB:

    USB 3.1 Bus:

      Host Controller Driver: AppleT8103USBXHCI

    USB 3.1 Bus:

      Host Controller Driver: AppleT8103USBXHCI

        USB3.1 Hub:

        USB2.1 Hub:

            2.4G Wireless Keyboard:

    USB 3.0 Bus:

      Host Controller Driver: AppleEmbeddedUSBXHCIFL1100

        USB Receiver:
```

## 2. 입력 값 확인

맥의 키보드의 입력 정보는 다음 사이트에서 확인할 수 있다.
https://hidutil-generator.netlify.app/

문제는 위 사이트에서 확인할 수 없는 키에 대해서 궁금할 수 있다.
다음은 HID Code과 EventTap의 key값을 확인하는 프로그램이다.

keyboard_input_listener.c

```c
#include <ApplicationServices/ApplicationServices.h>
#include <IOKit/hid/IOHIDManager.h>
#include <stdio.h>

// 키보드 이벤트를 감지하는 콜백 함수
void HIDKeyboardCallback(void *context, IOReturn result, void *sender, IOHIDValueRef value) {
    IOHIDElementRef element = IOHIDValueGetElement(value);
    uint32_t usagePage = IOHIDElementGetUsagePage(element);
    uint32_t usage = IOHIDElementGetUsage(element);
    int pressed = IOHIDValueGetIntegerValue(value);

    // 키가 눌렸을 때만 출력
    if (usagePage == 0x07 && pressed) {
        printf("HIDManager - Key Pressed: HID Code: 0x%X, KeyCode: %d\n", usage, usage);
        fflush(stdout);
    }
}

// 시스템 단축키 감지를 위한 Quartz Event Tap 콜백 함수
CGEventRef eventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    if (type == kCGEventKeyDown || type == kCGEventFlagsChanged) {
        CGKeyCode keycode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
        printf("EventTap - Key Pressed: KeyCode: %d, 0x%X\n", keycode, keycode);
        fflush(stdout);
    }
    return event;
}

// 현재 연결된 키보드 정보 출력
void PrintConnectedKeyboards(IOHIDManagerRef manager) {
    CFSetRef deviceSet = IOHIDManagerCopyDevices(manager);
    if (!deviceSet) {
        printf("No connected keyboards found.\n");
        return;
    }

    CFIndex count = CFSetGetCount(deviceSet);
    IOHIDDeviceRef devices[count];
    CFSetGetValues(deviceSet, (const void **)devices);

    printf("Connected Keyboards:\n");
    for (CFIndex i = 0; i < count; i++) {
        IOHIDDeviceRef device = devices[i];
        CFNumberRef vendorIdRef = IOHIDDeviceGetProperty(device, CFSTR(kIOHIDVendorIDKey));
        CFNumberRef productIdRef = IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductIDKey));
        CFStringRef productNameRef = IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductKey));

        int vendorId = 0, productId = 0;
        char productName[256] = "Unknown";

        if (vendorIdRef) CFNumberGetValue(vendorIdRef, kCFNumberIntType, &vendorId);
        if (productIdRef) CFNumberGetValue(productIdRef, kCFNumberIntType, &productId);
        if (productNameRef) CFStringGetCString(productNameRef, productName, sizeof(productName), kCFStringEncodingUTF8);

        printf(" - Vendor ID: %d, Product ID: %d, Name: %s\n", vendorId, productId, productName);
    }
    CFRelease(deviceSet);
}

int main() {
    // IOHIDManager 초기화
    IOHIDManagerRef hidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
    IOHIDManagerSetDeviceMatching(hidManager, NULL);
    IOHIDManagerRegisterInputValueCallback(hidManager, HIDKeyboardCallback, NULL);
    IOHIDManagerScheduleWithRunLoop(hidManager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    IOHIDManagerOpen(hidManager, kIOHIDOptionsTypeNone);

    // Quartz Event Tap 생성 (시스템 단축키 감지)
    CGEventMask eventMask = (1 << kCGEventKeyDown) | (1 << kCGEventFlagsChanged);
    CFMachPortRef eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0, eventMask, eventCallback, NULL);
    if (!eventTap) {
        fprintf(stderr, "Failed to create event tap. Try running with sudo.\n");
        return 1;
    }
    CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    CGEventTapEnable(eventTap, true);

    // 현재 연결된 키보드 목록 출력
    PrintConnectedKeyboards(hidManager);

    printf("\nListening for keyboard events... (Press keys to see their HID codes)\n");
    CFRunLoopRun(); // 이벤트 루프 실행

    return 0;
}
```

빌드 & 실행

```sh
# 빌드
gcc -o keyboard_event_checker keyboard_event_checker.c -framework ApplicationServices -framework CoreFoundation -framework IOKit
# 실행
./keyboard_event_checker
# 출력 예시:
HIDManager - Key Pressed: HID Code: 0x3F, KeyCode: 63
EventTap - Key Pressed: KeyCode: 97, 0x61
```

## 3. 입력 값 변경

### 3.1. hidutil을 이용한 변경

나의 경우 f1(밝기), f2(밝기), f7(이전), f8(일시정지/재생), f9(다음), f10(음소거),
f11(볼륨), f12(볼륨)가 특수키로 동작하고 있어 다음과 같이 일반키로 동작할 수 있도록 다음과 같이 스크립트를 작성하였다.
또, 추가로 오른쪽 커맨드를 한영키로 사용하기 위해 f18에 해당하는 키 값으로 변경해 주었다.

> 키보드 정보에서 확인한 내용을 이용해 특정 키보드에 한하여 동작할 수 있도록 'matching' 옵션을 활용
> 키보드 구분을 원하지 않을 경우 'matching' 옵션 내용을 삭제한다.

```sh
#!/bin/sh
/usr/bin/hidutil property --matching '[{"VendorID":12625,"ProductID":16400},{"VendorID":12625,"ProductID":16402}]' --set '{
    "UserKeyMapping": [
        {
            "HIDKeyboardModifierMappingSrc":0x7000000e7,
            "HIDKeyboardModifierMappingDst":0x70000006d
        },
        {
            "HIDKeyboardModifierMappingSrc": 0xC00000070,
            "HIDKeyboardModifierMappingDst": 0x70000003A
        },
        {
            "HIDKeyboardModifierMappingSrc": 0xC0000006F,
            "HIDKeyboardModifierMappingDst": 0x70000003B
        },
        {
            "HIDKeyboardModifierMappingSrc": 0xC000000B6,
            "HIDKeyboardModifierMappingDst": 0x700000040
        },
        {
            "HIDKeyboardModifierMappingSrc": 0xC000000CD,
            "HIDKeyboardModifierMappingDst": 0x700000041
        },
        {
            "HIDKeyboardModifierMappingSrc": 0xC000000B5,
            "HIDKeyboardModifierMappingDst": 0x700000042
        },
        {
            "HIDKeyboardModifierMappingSrc": 0xC000000E2,
            "HIDKeyboardModifierMappingDst": 0x700000043
        },
        {
            "HIDKeyboardModifierMappingSrc": 0xC000000EA,
            "HIDKeyboardModifierMappingDst": 0x700000044
        },
        {
            "HIDKeyboardModifierMappingSrc": 0xC000000E9,
            "HIDKeyboardModifierMappingDst": 0x700000045
        }
    ]
}'
```

위 스크립트 내용을 설명하면 다음과 같다.  

1. right cmd -> f18
2. 화면 밝기 감소 -> f1
3. 화면 밝기 증가 -> f2
4. 이전 트랙 -> f7
5. 일시정지/재생 -> f8
6. 다음 트랙 -> f9
7. 음소거 -> f10
8. 볼륨 감소 -> f11
9. 볼륨 증가 -> f12

### 3.2. interceptor 를 이용한 변경

1에서 확인한 키보드 정보와 키 코드(160 - f3에 설정된 mission_control)를 인터셉트하여 변경하도록 다음과 같이 코드를 작성하였다.

```c
#include <ApplicationServices/ApplicationServices.h>
#include <stdio.h>
#include <IOKit/hid/IOHIDManager.h>

// Bluetooth
#define BL_VENDOR_ID 12625      // 0x3151
#define BL_PRODUCT_ID 16402     // 0x4012
// USB
#define USB_PRODUCT_ID 16400    // 0x4010
#define USB_VENDOR_ID 12625     // 0x3151

IOHIDManagerRef hidManager;

// 특정 키보드 찾기
bool isTargetKeyboard(IOHIDDeviceRef device) {
    CFNumberRef vendorIdRef = IOHIDDeviceGetProperty(device, CFSTR(kIOHIDVendorIDKey));
    CFNumberRef productIdRef = IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductIDKey));

    int vendorId = 0, productId = 0;

    if (vendorIdRef) CFNumberGetValue(vendorIdRef, kCFNumberIntType, &vendorId);
    if (productIdRef) CFNumberGetValue(productIdRef, kCFNumberIntType, &productId);

    if(vendorId == BL_VENDOR_ID && productId == BL_PRODUCT_ID) return true;
    if(vendorId == USB_VENDOR_ID && productId == USB_PRODUCT_ID) return true;
    return false;
}

// 키 이벤트를 가로채서 변경하는 콜백 함수
CGEventRef eventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    if (type == kCGEventKeyDown || type == kCGEventKeyUp || type == kCGEventFlagsChanged) {
        // 키 코드 가져오기
        CGKeyCode keycode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);

        if (keycode == 160) { // KeyCode 160 일 경우
            // 연결된 HID 장치 목록에서 특정 키보드인지 확인
            CFSetRef deviceSet = IOHIDManagerCopyDevices(hidManager);
            if (deviceSet) {
                CFIndex count = CFSetGetCount(deviceSet);
                IOHIDDeviceRef devices[count];
                CFSetGetValues(deviceSet, (const void **)devices);

                for (CFIndex i = 0; i < count; i++) {
                    // 특정 키보드인지 확인
                    if (isTargetKeyboard(devices[i])) {
                        // → F3(KeyCode 99)로 변경
                        if (type == kCGEventKeyDown) { // 키가 눌렸을 때만 변경
                            printf("Intercepted Key 160 (Press) on Target Keyboard -> Changing to F3 (KeyCode 99)\n");
                            CGEventSetIntegerValueField(event, kCGKeyboardEventKeycode, 99);
                        } else if (type == kCGEventKeyUp) {
                            printf("Intercepted Key 160 (Release) on Target Keyboard -> Changing to F3 release (KeyCode 99)\n");
                            CGEventSetIntegerValueField(event, kCGKeyboardEventKeycode, 99);
                        }
                        CFRelease(deviceSet);
                        return event;
                    }
                }
                CFRelease(deviceSet);
            }
        }
    }
    return event;
}

int main() {
    // IOHIDManager 초기화
    hidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
    IOHIDManagerSetDeviceMatching(hidManager, NULL);
    IOHIDManagerOpen(hidManager, kIOHIDOptionsTypeNone);

    // 이벤트 후킹을 위한 Event Tap 생성
    // CGEventMask eventMask = (1 << kCGEventKeyDown) | (1 << kCGEventFlagsChanged);
    CGEventMask eventMask = (1 << kCGEventKeyDown) | (1 << kCGEventKeyUp) | (1 << kCGEventFlagsChanged);
    CFMachPortRef eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0, eventMask, eventCallback, NULL);

    if (!eventTap) {
        fprintf(stderr, "Failed to create event tap. Try running with sudo.\n");
        return 1;
    }

    // 이벤트 후킹을 실행
    CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    CGEventTapEnable(eventTap, true);

    printf("Listening for keyboard(feker 18) events and modifying KeyCode 160 -> 99 (F3)...\n");
    CFRunLoopRun(); // 이벤트 루프 실행
    return 0;
}
```

빌드 & 실행

```sh
gcc -o system_event_interceptor system_event_interceptor.c -framework ApplicationServices -framework CoreFoundation -framework IOKit

./system_event_interceptor
```

## 4. 동작 확인

특수기능 키를 모두 일반키로 변경하였으니 인터넷에서 키보드 테스트를 검색하여 테스트해보자.

## 5. 부팅 시 자동 실행

부팅 시 자동 실행은 다음에 정리를 추가하여 올리고자 한다.

/Library/LaunchAgent
/User/Shared/bin 

launchctl ...


