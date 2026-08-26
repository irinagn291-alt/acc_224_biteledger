#!/usr/bin/env python3
"""Emit Main.storyboard with every scene, IBOutlet and segue."""
from pathlib import Path

OUT = Path("/Users/belzephyrus/Documents/gambling/21AUG/App02_BiteLedger/BiteLedger/Base.lproj/Main.storyboard")


def color(name, r, g, b):
    return f'''    <namedColor name="{name}">
      <color red="{r}" green="{g}" blue="{b}" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
    </namedColor>'''


xml = r'''<?xml version="1.0" encoding="UTF-8"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="22900" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" useTraitCollections="YES" useSafeAreas="YES" colorMatched="YES" initialViewController="LCH1">
    <device id="retina6_1" orientation="portrait" appearance="light"/>
    <dependencies>
        <deployment identifier="iOS"/>
        <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="22900"/>
        <capability name="Named colors" minToolsVersion="9.0"/>
        <capability name="Safe area layout guides" minToolsVersion="9.0"/>
        <capability name="documents saved in the Xcode 8 format" minToolsVersion="8.0"/>
    </dependencies>
    <scenes>
        <scene sceneID="sLCH">
            <objects>
                <viewController storyboardIdentifier="BLGLaunchViewController" useStoryboardIdentifierAsRestorationIdentifier="YES" id="LCH1" customClass="BLGLaunchViewController" customModule="BiteLedger" customModuleProvider="target" sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="LCHV">
                        <rect key="frame" x="0.0" y="0.0" width="414" height="896"/>
                        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                        <subviews>
                            <imageView clipsSubviews="YES" userInteractionEnabled="NO" contentMode="scaleAspectFill" image="blg_Splash" translatesAutoresizingMaskIntoConstraints="NO" id="LCHI"/>
                        </subviews>
                        <viewLayoutGuide key="safeArea" id="LCHS"/>
                        <color key="backgroundColor" name="blg_background"/>
                        <constraints>
                            <constraint firstItem="LCHI" firstAttribute="top" secondItem="LCHV" secondAttribute="top" id="LCc1"/>
                            <constraint firstItem="LCHI" firstAttribute="leading" secondItem="LCHV" secondAttribute="leading" id="LCc2"/>
                            <constraint firstItem="LCHI" firstAttribute="trailing" secondItem="LCHV" secondAttribute="trailing" id="LCc3"/>
                            <constraint firstItem="LCHI" firstAttribute="bottom" secondItem="LCHV" secondAttribute="bottom" id="LCc4"/>
                        </constraints>
                    </view>
                    <connections>
                        <outlet property="blgSplashView" destination="LCHI" id="LCo1"/>
                        <segue destination="ONB1" kind="presentation" identifier="blg_presentOnboarding" modalPresentationStyle="fullScreen" id="LCg1"/>
                        <segue destination="DRW1" kind="presentation" identifier="blg_presentDrawer" modalPresentationStyle="fullScreen" id="LCg2"/>
                    </connections>
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="LCHF" userLabel="First Responder" sceneMemberID="firstResponder"/>
            </objects>
            <point key="canvasLocation" x="-900" y="0"/>
        </scene>
        <scene sceneID="sONB">
            <objects>
                <viewController storyboardIdentifier="BLGOnboardingViewController" useStoryboardIdentifierAsRestorationIdentifier="YES" id="ONB1" customClass="BLGOnboardingViewController" customModule="BiteLedger" customModuleProvider="target" sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="ONBV">
                        <rect key="frame" x="0.0" y="0.0" width="414" height="896"/>
                        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                        <subviews>
                            <scrollView clipsSubviews="YES" multipleTouchEnabled="YES" contentMode="scaleToFill" translatesAutoresizingMaskIntoConstraints="NO" id="ONBS">
                                <subviews>
                                    <stackView opaque="NO" contentMode="scaleToFill" axis="vertical" alignment="fill" spacing="16" translatesAutoresizingMaskIntoConstraints="NO" id="ONBK">
                                        <subviews>
                                            <imageView clipsSubviews="YES" userInteractionEnabled="NO" contentMode="scaleAspectFit" image="blg_Onboarding1" translatesAutoresizingMaskIntoConstraints="NO" id="ONBI">
                                                <constraints>
                                                    <constraint firstAttribute="height" constant="280" id="ONh1"/>
                                                </constraints>
                                            </imageView>
                                            <label opaque="NO" userInteractionEnabled="NO" contentMode="left" text="Title" textAlignment="center" lineBreakMode="tailTruncation" numberOfLines="0" translatesAutoresizingMaskIntoConstraints="NO" id="ONBT"/>
                                            <label opaque="NO" userInteractionEnabled="NO" contentMode="left" text="Body" textAlignment="center" lineBreakMode="tailTruncation" numberOfLines="0" translatesAutoresizingMaskIntoConstraints="NO" id="ONBB"/>
                                            <stackView hidden="YES" opaque="NO" contentMode="scaleToFill" axis="vertical" spacing="8" translatesAutoresizingMaskIntoConstraints="NO" id="ONBX">
                                                <subviews>
                                                    <textField opaque="NO" contentMode="scaleToFill" placeholder="kcal" textAlignment="natural" minimumFontSize="17" translatesAutoresizingMaskIntoConstraints="NO" id="ONBF1">
                                                        <constraints>
                                                            <constraint firstAttribute="height" relation="greaterThanOrEqual" constant="44" id="ONf1"/>
                                                        </constraints>
                                                    </textField>
                                                    <textField opaque="NO" contentMode="scaleToFill" placeholder="protein" textAlignment="natural" minimumFontSize="17" translatesAutoresizingMaskIntoConstraints="NO" id="ONBF2">
                                                        <constraints>
                                                            <constraint firstAttribute="height" relation="greaterThanOrEqual" constant="44" id="ONf2"/>
                                                        </constraints>
                                                    </textField>
                                                    <textField opaque="NO" contentMode="scaleToFill" placeholder="carbs" textAlignment="natural" minimumFontSize="17" translatesAutoresizingMaskIntoConstraints="NO" id="ONBF3">
                                                        <constraints>
                                                            <constraint firstAttribute="height" relation="greaterThanOrEqual" constant="44" id="ONf3"/>
                                                        </constraints>
                                                    </textField>
                                                    <textField opaque="NO" contentMode="scaleToFill" placeholder="fat" textAlignment="natural" minimumFontSize="17" translatesAutoresizingMaskIntoConstraints="NO" id="ONBF4">
                                                        <constraints>
                                                            <constraint firstAttribute="height" relation="greaterThanOrEqual" constant="44" id="ONf4"/>
                                                        </constraints>
                                                    </textField>
                                                </subviews>
                                            </stackView>
                                            <pageControl opaque="NO" contentMode="scaleToFill" contentHorizontalAlignment="center" numberOfPages="4" translatesAutoresizingMaskIntoConstraints="NO" id="ONBP"/>
                                            <button opaque="NO" contentMode="scaleToFill" contentHorizontalAlignment="center" contentVerticalAlignment="center" buttonType="system" lineBreakMode="middleTruncation" translatesAutoresizingMaskIntoConstraints="NO" id="ONBN">
                                                <constraints>
                                                    <constraint firstAttribute="height" relation="greaterThanOrEqual" constant="44" id="ONn1"/>
                                                </constraints>
                                                <state key="normal" title="Next"/>
                                                <connections>
                                                    <action selector="blg_next:" destination="ONB1" eventType="touchUpInside" id="ONa1"/>
                                                </connections>
                                            </button>
                                            <button opaque="NO" contentMode="scaleToFill" contentHorizontalAlignment="center" contentVerticalAlignment="center" buttonType="system" lineBreakMode="middleTruncation" translatesAutoresizingMaskIntoConstraints="NO" id="ONBK2">
                                                <constraints>
                                                    <constraint firstAttribute="height" relation="greaterThanOrEqual" constant="44" id="ONn2"/>
                                                </constraints>
                                                <state key="normal" title="Skip"/>
                                                <connections>
                                                    <action selector="blg_skip:" destination="ONB1" eventType="touchUpInside" id="ONa2"/>
                                                </connections>
                                            </button>
                                        </subviews>
                                    </stackView>
                                </subviews>
                                <constraints>
                                    <constraint firstItem="ONBK" firstAttribute="leading" secondItem="ONBS" secondAttribute="leading" constant="24" id="ONs1"/>
                                    <constraint firstItem="ONBK" firstAttribute="trailing" secondItem="ONBS" secondAttribute="trailing" constant="-24" id="ONs2"/>
                                    <constraint firstItem="ONBK" firstAttribute="top" secondItem="ONBS" secondAttribute="top" constant="16" id="ONs3"/>
                                    <constraint firstItem="ONBK" firstAttribute="bottom" secondItem="ONBS" secondAttribute="bottom" constant="-16" id="ONs4"/>
                                    <constraint firstItem="ONBK" firstAttribute="width" secondItem="ONBS" secondAttribute="width" constant="-48" id="ONs5"/>
                                </constraints>
                            </scrollView>
                        </subviews>
                        <viewLayoutGuide key="safeArea" id="ONBA"/>
                        <color key="backgroundColor" name="blg_background"/>
                        <constraints>
                            <constraint firstItem="ONBS" firstAttribute="top" secondItem="ONBA" secondAttribute="top" id="ONc1"/>
                            <constraint firstItem="ONBS" firstAttribute="leading" secondItem="ONBA" secondAttribute="leading" id="ONc2"/>
                            <constraint firstItem="ONBS" firstAttribute="trailing" secondItem="ONBA" secondAttribute="trailing" id="ONc3"/>
                            <constraint firstItem="ONBS" firstAttribute="bottom" secondItem="ONBA" secondAttribute="bottom" id="ONc4"/>
                        </constraints>
                    </view>
                    <connections>
                        <outlet property="blgScrollView" destination="ONBS" id="ONo1"/>
                        <outlet property="blgImageView" destination="ONBI" id="ONo2"/>
                        <outlet property="blgTitleLabel" destination="ONBT" id="ONo3"/>
                        <outlet property="blgBodyLabel" destination="ONBB" id="ONo4"/>
                        <outlet property="blgPageControl" destination="ONBP" id="ONo5"/>
                        <outlet property="blgSkipButton" destination="ONBK2" id="ONo6"/>
                        <outlet property="blgNextButton" destination="ONBN" id="ONo7"/>
                        <outlet property="blgTargetsStack" destination="ONBX" id="ONo8"/>
                        <outlet property="blgKcalField" destination="ONBF1" id="ONo9"/>
                        <outlet property="blgProteinField" destination="ONBF2" id="ONo10"/>
                        <outlet property="blgCarbsField" destination="ONBF3" id="ONo11"/>
                        <outlet property="blgFatField" destination="ONBF4" id="ONo12"/>
                        <segue destination="DRW1" kind="presentation" identifier="blg_presentDrawer" modalPresentationStyle="fullScreen" id="ONg1"/>
                    </connections>
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="ONBF" userLabel="First Responder" sceneMemberID="firstResponder"/>
            </objects>
            <point key="canvasLocation" x="-400" y="0"/>
        </scene>
        <scene sceneID="sDRW">
            <objects>
                <viewController storyboardIdentifier="BLGDrawerContainerController" useStoryboardIdentifierAsRestorationIdentifier="YES" id="DRW1" customClass="BLGDrawerContainerController" customModule="BiteLedger" customModuleProvider="target" sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="DRWV">
                        <rect key="frame" x="0.0" y="0.0" width="414" height="896"/>
                        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                        <subviews>
                            <containerView opaque="NO" contentMode="scaleToFill" translatesAutoresizingMaskIntoConstraints="NO" id="DRWC">
                                <connections>
                                    <segue destination="NAV1" kind="embed" identifier="blg_embedNav" id="DRWg1"/>
                                </connections>
                            </containerView>
                            <view alpha="0.0" contentMode="scaleToFill" translatesAutoresizingMaskIntoConstraints="NO" id="DRWD">
                                <color key="backgroundColor" name="blg_ink"/>
                            </view>
                            <view contentMode="scaleToFill" translatesAutoresizingMaskIntoConstraints="NO" id="DRWM">
                                <subviews>
                                    <tableView clipsSubviews="YES" contentMode="scaleToFill" alwaysBounceVertical="YES" dataMode="prototypes" style="plain" separatorStyle="default" rowHeight="52" estimatedRowHeight="52" sectionHeaderHeight="-1" sectionFooterHeight="-1" translatesAutoresizingMaskIntoConstraints="NO" id="DRWT">
                                        <color key="backgroundColor" name="blg_surface"/>
                                        <prototypes>
                                            <tableViewCell clipsSubviews="YES" contentMode="scaleToFill" insetsLayoutMarginsFromSafeArea="NO" selectionStyle="default" indentationWidth="10" reuseIdentifier="BLGDrawerCell" id="DRWTC">
                                                <rect key="frame" x="0.0" y="50" width="260" height="52"/>
                                                <autoresizingMask key="autoresizingMask"/>
                                                <tableViewCellContentView key="contentView" opaque="NO" clipsSubviews="YES" multipleTouchEnabled="YES" contentMode="center" id="DRWTV"/>
                                            </tableViewCell>
                                        </prototypes>
                                    </tableView>
                                </subviews>
                                <color key="backgroundColor" name="blg_surface"/>
                                <constraints>
                                    <constraint firstAttribute="width" constant="260" id="DRWw1"/>
                                    <constraint firstItem="DRWT" firstAttribute="top" secondItem="DRWM" secondAttribute="top" id="DRWw2"/>
                                    <constraint firstItem="DRWT" firstAttribute="leading" secondItem="DRWM" secondAttribute="leading" id="DRWw3"/>
                                    <constraint firstItem="DRWT" firstAttribute="trailing" secondItem="DRWM" secondAttribute="trailing" id="DRWw4"/>
                                    <constraint firstItem="DRWT" firstAttribute="bottom" secondItem="DRWM" secondAttribute="bottom" id="DRWw5"/>
                                </constraints>
                            </view>
                        </subviews>
                        <viewLayoutGuide key="safeArea" id="DRWA"/>
                        <color key="backgroundColor" name="blg_background"/>
                        <constraints>
                            <constraint firstItem="DRWC" firstAttribute="top" secondItem="DRWV" secondAttribute="top" id="DRc1"/>
                            <constraint firstItem="DRWC" firstAttribute="leading" secondItem="DRWV" secondAttribute="leading" id="DRc2"/>
                            <constraint firstItem="DRWC" firstAttribute="trailing" secondItem="DRWV" secondAttribute="trailing" id="DRc3"/>
                            <constraint firstItem="DRWC" firstAttribute="bottom" secondItem="DRWV" secondAttribute="bottom" id="DRc4"/>
                            <constraint firstItem="DRWD" firstAttribute="top" secondItem="DRWV" secondAttribute="top" id="DRc5"/>
                            <constraint firstItem="DRWD" firstAttribute="leading" secondItem="DRWV" secondAttribute="leading" id="DRc6"/>
                            <constraint firstItem="DRWD" firstAttribute="trailing" secondItem="DRWV" secondAttribute="trailing" id="DRc7"/>
                            <constraint firstItem="DRWD" firstAttribute="bottom" secondItem="DRWV" secondAttribute="bottom" id="DRc8"/>
                            <constraint firstItem="DRWM" firstAttribute="top" secondItem="DRWV" secondAttribute="top" id="DRc9"/>
                            <constraint firstItem="DRWM" firstAttribute="bottom" secondItem="DRWV" secondAttribute="bottom" id="DRc10"/>
                            <constraint firstItem="DRWM" firstAttribute="leading" secondItem="DRWV" secondAttribute="leading" constant="-260" id="DRc11"/>
                        </constraints>
                    </view>
                    <connections>
                        <outlet property="blgContentContainer" destination="DRWC" id="DRo1"/>
                        <outlet property="blgDimView" destination="DRWD" id="DRo2"/>
                        <outlet property="blgMenuView" destination="DRWM" id="DRo3"/>
                        <outlet property="blgMenuTableView" destination="DRWT" id="DRo4"/>
                        <outlet property="blgMenuLeading" destination="DRc11" id="DRo5"/>
                    </connections>
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="DRWF" userLabel="First Responder" sceneMemberID="firstResponder"/>
            </objects>
            <point key="canvasLocation" x="200" y="0"/>
        </scene>
        <scene sceneID="sNAV">
            <objects>
                <navigationController storyboardIdentifier="BLGRootNavigation" automaticallyAdjustsScrollViewInsets="NO" id="NAV1" sceneMemberID="viewController">
                    <navigationBar key="navigationBar" contentMode="scaleToFill" id="NAVB">
                        <rect key="frame" x="0.0" y="48" width="414" height="44"/>
                        <autoresizingMask key="autoresizingMask"/>
                    </navigationBar>
                    <connections>
                        <segue destination="LED1" kind="relationship" relationship="rootViewController" id="NAVg1"/>
                    </connections>
                </navigationController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="NAVF" userLabel="First Responder" sceneMemberID="firstResponder"/>
            </objects>
            <point key="canvasLocation" x="700" y="0"/>
        </scene>
'''

# Continue in second part to keep this manageable - I'll write the rest of scenes in the same file
# Actually I'll complete the file now with remaining scenes.

rest = r'''
        <scene sceneID="sLED">
            <objects>
                <viewController storyboardIdentifier="BLGLedgerViewController" useStoryboardIdentifierAsRestorationIdentifier="YES" id="LED1" customClass="BLGLedgerViewController" customModule="BiteLedger" customModuleProvider="target" sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="LEDV">
                        <rect key="frame" x="0.0" y="0.0" width="414" height="896"/>
                        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                        <subviews>
                            <scrollView clipsSubviews="YES" multipleTouchEnabled="YES" contentMode="scaleToFill" translatesAutoresizingMaskIntoConstraints="NO" id="LEDS">
                                <subviews>
                                    <stackView opaque="NO" contentMode="scaleToFill" axis="vertical" spacing="12" translatesAutoresizingMaskIntoConstraints="NO" id="LEDK">
                                        <subviews>
                                            <imageView clipsSubviews="YES" userInteractionEnabled="NO" contentMode="scaleAspectFill" image="blg_HeaderDecor" translatesAutoresizingMaskIntoConstraints="NO" id="LEDH">
                                                <constraints>
                                                    <constraint firstAttribute="height" constant="88" id="LEh1"/>
                                                </constraints>
                                            </imageView>
                                            <label opaque="NO" userInteractionEnabled="NO" contentMode="left" text="Day" lineBreakMode="tailTruncation" translatesAutoresizingMaskIntoConstraints="NO" id="LEDD"/>
                                            <label opaque="NO" userInteractionEnabled="NO" contentMode="left" text="0" textAlignment="center" lineBreakMode="tailTruncation" translatesAutoresizingMaskIntoConstraints="NO" id="LEDE"/>
                                            <label opaque="NO" userInteractionEnabled="NO" contentMode="left" text="of target" textAlignment="center" lineBreakMode="tailTruncation" translatesAutoresizingMaskIntoConstraints="NO" id="LEDT"/>
                                            <label opaque="NO" userInteractionEnabled="NO" contentMode="left" text="Balance" textAlignment="center" lineBreakMode="tailTruncation" translatesAutoresizingMaskIntoConstraints="NO" id="LEDB"/>
                                            <label hidden="YES" opaque="NO" userInteractionEnabled="NO" contentMode="left" text="Over budget" textAlignment="center" lineBreakMode="tailTruncation" translatesAutoresizingMaskIntoConstraints="NO" id="LEDO"/>
                                            <stackView opaque="NO" contentMode="scaleToFill" distribution="fillEqually" spacing="8" translatesAutoresizingMaskIntoConstraints="NO" id="LEDM">
                                                <subviews>
                                                    <stackView opaque="NO" contentMode="scaleToFill" axis="vertical" alignment="center" spacing="4" translatesAutoresizingMaskIntoConstraints="NO" id="LEDMP">
                                                        <subviews>
                                                            <imageView clipsSubviews="YES" userInteractionEnabled="NO" contentMode="scaleAspectFit" image="blg_MacroProtein" translatesAutoresizingMaskIntoConstraints="NO" id="LEDIP">
                                                                <constraints>
                                                                    <constraint firstAttribute="height" constant="32" id="LEi1"/>
                                                                    <constraint firstAttribute="width" constant="32" id="LEi2"/>
                                                                </constraints>
                                                            </imageView>
                                                            <label opaque="NO" userInteractionEnabled="NO" contentMode="left" text="P" textAlignment="center" lineBreakMode="tailTruncation" numberOfLines="0" translatesAutoresizingMaskIntoConstraints="NO" id="LEDLP"/>
                                                        </subviews>
                                                    </stackView>
                                                    <stackView opaque="NO" contentMode="scaleToFill" axis="vertical" alignment="center" spacing="4" translatesAutoresizingMaskIntoConstraints="NO" id="LEDMC">
                                                        <subviews>
                                                            <imageView clipsSubviews="YES" userInteractionEnabled="NO" contentMode="scaleAspectFit" image="blg_MacroCarbs" translatesAutoresizingMaskIntoConstraints="NO" id="LEDIC">
                                                                <constraints>
                                                                    <constraint firstAttribute="height" constant="32" id="LEi3"/>
                                                                    <constraint firstAttribute="width" constant="32" id="LEi4"/>
                                                                </constraints>
                                                            </imageView>
                                                            <label opaque="NO" userInteractionEnabled="NO" contentMode="left" text="C" textAlignment="center" lineBreakMode="tailTruncation" numberOfLines="0" translatesAutoresizingMaskIntoConstraints="NO" id="LEDLC"/>
                                                        </subviews>
                                                    </stackView>
                                                    <stackView opaque="NO" contentMode="scaleToFill" axis="vertical" alignment="center" spacing="4" translatesAutoresizingMaskIntoConstraints="NO" id="LEDMF">
                                                        <subviews>
                                                            <imageView clipsSubviews="YES" userInteractionEnabled="NO" contentMode="scaleAspectFit" image="blg_MacroFat" translatesAutoresizingMaskIntoConstraints="NO" id="LEDIF">
                                                                <constraints>
                                                                    <constraint firstAttribute="height" constant="32" id="LEi5"/>
                                                                    <constraint firstAttribute="width" constant="32" id="LEi6"/>
                                                                </constraints>
                                                            </imageView>
                                                            <label opaque="NO" userInteractionEnabled="NO" contentMode="left" text="F" textAlignment="center" lineBreakMode="tailTruncation" numberOfLines="0" translatesAutoresizingMaskIntoConstraints="NO" id="LEDLF"/>
                                                        </subviews>
                                                    </stackView>
                                                </subviews>
                                            </stackView>
                                            <stackView opaque="NO" contentMode="scaleToFill" distribution="fillEqually" spacing="8" translatesAutoresizingMaskIntoConstraints="NO" id="LEDN">
                                                <subviews>
                                                    <button opaque="NO" contentMode="scaleToFill" contentHorizontalAlignment="center" contentVerticalAlignment="center" buttonType="system" translatesAutoresizingMaskIntoConstraints="NO" id="LEDB1">
                                                        <constraints>
                                                            <constraint firstAttribute="height" relation="greaterThanOrEqual" constant="44" id="LEb1"/>
                                                        </constraints>
                                                        <state key="normal" title="Lookup"/>
                                                        <connections>
                                                            <action selector="blg_openLookup:" destination="LED1" eventType="touchUpInside" id="LEa1"/>
                                                        </connections>
                                                    </button>
                                                    <button opaque="NO" contentMode="scaleToFill" contentHorizontalAlignment="center" contentVerticalAlignment="center" buttonType="system" translatesAutoresizingMaskIntoConstraints="NO" id="LEDB2">
                                                        <constraints>
                                                            <constraint firstAttribute="height" relation="greaterThanOrEqual" constant="44" id="LEb2"/>
                                                        </constraints>
                                                        <state key="normal" title="Scan"/>
                                                        <connections>
                                                            <action selector="blg_openScan:" destination="LED1" eventType="touchUpInside" id="LEa2"/>
                                                        </connections>
                                                    </button>
                                                </subviews>
                                            </stackView>
                                            <button opaque="NO" contentMode="scaleToFill" contentHorizontalAlignment="center" contentVerticalAlignment="center" buttonType="system" translatesAutoresizingMaskIntoConstraints="NO" id="LEDB3">
                                                <constraints>
                                                    <constraint firstAttribute="height" relation="greaterThanOrEqual" constant="44" id="LEb3"/>
                                                </constraints>
                                                <state key="normal" title="Statement"/>
                                                <connections>
                                                    <action selector="blg_openStatement:" destination="LED1" eventType="touchUpInside" id="LEa3"/>
                                                </connections>
                                            </button>
                                            <tableView clipsSubviews="YES" contentMode="scaleToFill" alwaysBounceVertical="YES" dataMode="prototypes" style="plain" separatorStyle="default" rowHeight="72" translatesAutoresizingMaskIntoConstraints="NO" id="LEDTV">
                                                <constraints>
                                                    <constraint firstAttribute="height" constant="288" id="LEt1"/>
                                                </constraints>
                                                <prototypes>
                                                    <tableViewCell clipsSubviews="YES" contentMode="scaleToFill" selectionStyle="default" indentationWidth="10" reuseIdentifier="BLGEntryCell" id="LEDTC" customClass="BLGEntryCell" customModule="BiteLedger" customModuleProvider="target">
                                                        <rect key="frame" x="0.0" y="50" width="366" height="72"/>
                                                        <autoresizingMask key="autoresizingMask"/>
                                                        <tableViewCellContentView key="contentView" opaque="NO" clipsSubviews="YES" multipleTouchEnabled="YES" contentMode="center" id="LEDTW"/>
                                                    </tableViewCell>
                                                </prototypes>
                                            </tableView>
                                            <view contentMode="scaleToFill" translatesAutoresizingMaskIntoConstraints="NO" id="LEDEMP" customClass="BLGEmptyBoardView" customModule="BiteLedger" customModuleProvider="target">
                                                <constraints>
                                                    <constraint firstAttribute="height" constant="280" id="LEe1"/>
                                                </constraints>
                                            </view>
                                        </subviews>
                                    </stackView>
                                </subviews>
                                <constraints>
                                    <constraint firstItem="LEDK" firstAttribute="leading" secondItem="LEDS" secondAttribute="leading" constant="16" id="LEs1"/>
                                    <constraint firstItem="LEDK" firstAttribute="trailing" secondItem="LEDS" secondAttribute="trailing" constant="-16" id="LEs2"/>
                                    <constraint firstItem="LEDK" firstAttribute="top" secondItem="LEDS" secondAttribute="top" constant="8" id="LEs3"/>
                                    <constraint firstItem="LEDK" firstAttribute="bottom" secondItem="LEDS" secondAttribute="bottom" constant="-16" id="LEs4"/>
                                    <constraint firstItem="LEDK" firstAttribute="width" secondItem="LEDS" secondAttribute="width" constant="-32" id="LEs5"/>
                                </constraints>
                            </scrollView>
                        </subviews>
                        <viewLayoutGuide key="safeArea" id="LEDA"/>
                        <color key="backgroundColor" name="blg_background"/>
                        <constraints>
                            <constraint firstItem="LEDS" firstAttribute="top" secondItem="LEDA" secondAttribute="top" id="LEc1"/>
                            <constraint firstItem="LEDS" firstAttribute="leading" secondItem="LEDA" secondAttribute="leading" id="LEc2"/>
                            <constraint firstItem="LEDS" firstAttribute="trailing" secondItem="LEDA" secondAttribute="trailing" id="LEc3"/>
                            <constraint firstItem="LEDS" firstAttribute="bottom" secondItem="LEDA" secondAttribute="bottom" id="LEc4"/>
                        </constraints>
                    </view>
                    <navigationItem key="navigationItem" title="Ledger" id="LEDNIV">
                        <barButtonItem key="leftBarButtonItem" title="Prev" id="LEDPV">
                            <connections>
                                <action selector="blg_prevDay:" destination="LED1" id="LEa4"/>
                            </connections>
                        </barButtonItem>
                        <barButtonItem key="rightBarButtonItem" title="Next" id="LEDNX">
                            <connections>
                                <action selector="blg_nextDay:" destination="LED1" id="LEa5"/>
                            </connections>
                        </barButtonItem>
                    </navigationItem>
                    <connections>
                        <outlet property="blgScrollView" destination="LEDS" id="LEo1"/>
                        <outlet property="blgHeaderDecor" destination="LEDH" id="LEo2"/>
                        <outlet property="blgDayLabel" destination="LEDD" id="LEo3"/>
                        <outlet property="blgEnergyLabel" destination="LEDE" id="LEo4"/>
                        <outlet property="blgEnergyTargetLabel" destination="LEDT" id="LEo5"/>
                        <outlet property="blgBalanceLabel" destination="LEDB" id="LEo6"/>
                        <outlet property="blgProteinIcon" destination="LEDIP" id="LEo7"/>
                        <outlet property="blgCarbsIcon" destination="LEDIC" id="LEo8"/>
                        <outlet property="blgFatIcon" destination="LEDIF" id="LEo9"/>
                        <outlet property="blgProteinLabel" destination="LEDLP" id="LEo10"/>
                        <outlet property="blgCarbsLabel" destination="LEDLC" id="LEo11"/>
                        <outlet property="blgFatLabel" destination="LEDLF" id="LEo12"/>
                        <outlet property="blgTableView" destination="LEDTV" id="LEo13"/>
                        <outlet property="blgLookupButton" destination="LEDB1" id="LEo14"/>
                        <outlet property="blgScanButton" destination="LEDB2" id="LEo15"/>
                        <outlet property="blgStatementButton" destination="LEDB3" id="LEo16"/>
                        <outlet property="blgEmptyBoard" destination="LEDEMP" id="LEo17"/>
                        <outlet property="blgOverLabel" destination="LEDO" id="LEo18"/>
                        <outlet property="blgTableHeight" destination="LEt1" id="LEo19"/>
                        <segue destination="LUK1" kind="show" identifier="blg_showLookup" id="LEg1"/>
                        <segue destination="SCN1" kind="show" identifier="blg_showScan" id="LEg2"/>
                        <segue destination="STM1" kind="show" identifier="blg_showStatement" id="LEg3"/>
                    </connections>
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="LEDF" userLabel="First Responder" sceneMemberID="firstResponder"/>
            </objects>
            <point key="canvasLocation" x="1200" y="0"/>
        </scene>
'''

# I'll write remaining scenes as another string and concatenate
print("partial")
OUT.parent.mkdir(parents=True, exist_ok=True)
# The rest is written by the following continuation when this script is completed.
# For now we just mark path
print(OUT)
