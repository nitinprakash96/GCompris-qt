/* GCompris - LetterInWord.qml
 *
 * Copyright (C) 2014 Holger Kaelberer  <holger.k@elberer.de>
 *               2016 Akshat Tandon     <akshat.tandon@research.iiit.ac.in>
 *
 * Authors:
 *   Holger Kaelberer <holger.k@elberer.de> (Click on Letter - Qt Quick port)
 *   Akshat Tandon    <akshat.tandon@research.iiit.ac.in> (Modifications to Click on Letter code
 *                                                           to make Letter in which word activity)
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program; if not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.1
import QtGraphicalEffects 1.0
import GCompris 1.0
import "../../core"
import "letter-in-word.js" as Activity
import "qrc:/gcompris/src/core/core.js" as Core

ActivityBase {
    id: activity
    focus: true

    onStart: focus = true

    pageComponent: Image {
        id: background
        source: Activity.url + "images/background.svg"
        sourceSize.width: parent.width
        fillMode: Image.PreserveAspectCrop
        focus: true

        // system locale by default
        property string locale: "system"

        signal start
        signal stop
        signal voiceError

        Component.onCompleted: {
            dialogActivityConfig.getInitialConfiguration()
            activity.start.connect(start)
            activity.stop.connect(stop)
        }

        QtObject {
            id: items
            property Item main: activity.main
            property alias bar: bar
            property alias wordsModel: wordsModel
            property GCAudio audioVoices: activity.audioVoices
            property alias parser: parser
            property alias animateX: animateX
            property alias repeatItem: repeatItem
            property alias score: score
            property alias bonus: bonus
            property alias locale: background.locale
            property string question
        }



        onStart: {
            activity.audioVoices.error.connect(voiceError)
            Activity.start(items);
        }

        onStop: Activity.stop()

        DialogActivityConfig {
            id: dialogActivityConfig
            currentActivity: activity
            content: Component {
                Item {
                    property alias localeBox: localeBox
                    height: column.height

                    property alias availableLangs: langs.languages
                    LanguageList {
                        id: langs
                    }

                    Column {
                        id: column
                        spacing: 10
                        width: parent.width

                        Flow {
                            spacing: 5
                            width: dialogActivityConfig.width
                            GCComboBox {
                                id: localeBox
                                model: langs.languages
                                background: dialogActivityConfig
                                label: qsTr("Select your locale")
                            }
                        }
                    }
                }
            }

            onClose: home()
            onLoadData: {
                if(dataToSave && dataToSave["locale"]) {
                    background.locale = dataToSave["locale"];
                }
            }
            onSaveData: {
                var oldLocale = background.locale;
                var newLocale =
                dialogActivityConfig.configItem.availableLangs[dialogActivityConfig.loader.item.localeBox.currentIndex].locale;
                // Remove .UTF-8
                if(newLocale.indexOf('.') != -1) {
                    newLocale = newLocale.substring(0, newLocale.indexOf('.'))
                }
                dataToSave = {"locale": newLocale }

                background.locale = newLocale;

                // Restart the activity with new information
                if(oldLocale !== newLocale) {
                    background.stop();
                    background.start();
                }
            }

            function setDefaultValues() {
                var localeUtf8 = background.locale;
                if(background.locale != "system") {
                    localeUtf8 += ".UTF-8";
                }

                for(var i = 0 ; i < dialogActivityConfig.configItem.availableLangs.length ; i ++) {
                    if(dialogActivityConfig.configItem.availableLangs[i].locale === localeUtf8) {
                        dialogActivityConfig.loader.item.localeBox.currentIndex = i;
                        break;
                    }
                }
            }
        }

        DialogHelp {
            id: dialogHelpLeftRight
            onClose: home()
        }

        Bar {
            id: bar
            content: BarEnumContent { value: help | home | level | config }
            onHelpClicked: {
                displayDialog(dialogHelpLeftRight)
            }
            onPreviousLevelClicked: Activity.previousLevel()
            onNextLevelClicked: Activity.nextLevel()
            onHomeClicked: home()
            onConfigClicked: {
                dialogActivityConfig.active = true
                dialogActivityConfig.setDefaultValues()
                displayDialog(dialogActivityConfig)
            }
        }

        Score {
            id: score
            anchors.top: parent.top
            anchors.topMargin: 10 * ApplicationInfo.ratio
            anchors.left: parent.left
            anchors.leftMargin: 10 * ApplicationInfo.ratio
            anchors.bottom: undefined
            anchors.right: undefined
        }

        Bonus {
            id: bonus
            interval: 1000
            Component.onCompleted: {
                win.connect(Activity.nextSubLevel);
                loose.connect(Activity.incorrectSelection);
            }
        }

        BarButton {
            id: repeatItem
            source: "qrc:/gcompris/src/core/resource/bar_repeat.svg";
            sourceSize.width: 80 * ApplicationInfo.ratio
            anchors {
                top: parent.top
                right: parent.right
                margins: 10
            }
            onClicked:{
                Activity.playLetter(Activity.currentLetter);
                animateX.restart();
            }
        }

        Item {
            id: planeText
            width: plane.width
            height: plane.height
            x: - width
            anchors.top: parent.top
            anchors.topMargin: 5 * ApplicationInfo.ratio

            Image {
                id: plane
                anchors.centerIn: planeText
                anchors.top: parent.top
                source: Activity.url + "images/plane.svg"
                sourceSize.height: 90 * ApplicationInfo.ratio
            }

            GCText {
                id: questionItem
                anchors.right: planeText.right  
                anchors.rightMargin: 2 * plane.width / 3
                anchors.verticalCenter: planeText.verticalCenter
                anchors.bottomMargin: 10 * ApplicationInfo.ratio
                fontSize: hugeSize
                font.weight: Font.DemiBold
                color: "#2a2a2a"
                text: items.question

            }

            PropertyAnimation {
                id: animateX
                target: planeText
                properties: "x"
                from: - planeText.width
                //to:background.width/2 - planeText.width/2
                to: bar.level <= 2 ? background.width/4 : background.width
                duration: bar.level <= 2 ? 5500: 11000
                //easing.type: Easing.OutQuad
                easing.type: bar.level <= 2 ? Easing.OutQuad: Easing.OutInCirc
            }
        }

        ListModel {
            id: wordsModel
        }

        property int itemWidth: Math.min(parent.width / 7.5, parent.height / 5)
        property int itemHeight: itemWidth * 1.11

        GridView {
            id: wordsView
            anchors.bottom: bar.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: planeText.bottom
            anchors.topMargin: 10 * ApplicationInfo.ratio
            anchors.leftMargin: 5 * ApplicationInfo.ratio
            anchors.rightMargin: 5 * ApplicationInfo.ratio
            anchors.bottomMargin: 10 * ApplicationInfo.ratio
            cellWidth: itemWidth + 43*ApplicationInfo.ratio
            cellHeight: itemHeight + 15*ApplicationInfo.ratio
            clip: false
            interactive: false
            //verticalLayoutDirection: GridView.BottomToTop
            layoutDirection: Qt.LeftToRight


            model: wordsModel
            delegate: Card{
                width: background.itemWidth

            }
        }

        JsonParser {
            id: parser
            onError: console.error("Click_on_letter: Error parsing JSON: " + msg);
        }

    }
}