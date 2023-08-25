//---------------------------------------------------------------------
// DiatonicTab, MuseScore 3 plugin
//---------------------------------------------------------------------

//=============================================================================
//  MuseScore
//  Music Composition & Notation
//
//  Create Tablature for diatonic accordion from a MuseScore music score
//
//  Copyright (C) 2020  Jean-Michel Bencetti
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2
//  as published by the Free Software Foundation and appearing in
//  the file LICENCE.GPL
//
//=============================================================================

//--------------------------------------------------------------------------
/* This plugin adds the number of keys for diatonic accordion
     to create a very simplified form of tablature
     This plugin uses the lyrics text to put the key numbers
     in order to be able to vertically align pulls and pushes differently

  Author : Jean-Michel Bencetti
  Current version : 1.06
  Date : v1.00 : 2019-06-13 : développement initial
         v1.02 : 2019-09-02 : tient compte des accords main gauche pour proposer les notes en tiré ou en poussé
         v1.03 : 2019-10-11 : ajoute la possibilité de ne traiter que des mesures sélectionnées
	    v1.04 : 2020-02-24 : propose une fenêtre de dialogue pour utiliser différents critères
	    v1.05 : 2020-03-02 : gestion de plans de claviers différents
	                      mémorisation des parametres dans un fichier format json
	                      préparation à la traduction du plugin
	    v1.05.04 : 20200316: ajouts de claviers et corrections de quelques dysfonctionnements
      v1.06 : Externalisation des claviers
      v1.06.01 : 20200324 version initiale à partie de la version v1.06
      v1.06.02 : 20200326 externalisation des claviers main gauche
      v1.06.04 : 20200406 choix de souligner ou pas les tirés en C.A.D.B.
      V1.06.05 : 20200623 correctifs méthode Corgeron

  Description version v1.02 :
    Pour les accords main gauche A, Am, D, Dm, seules les touches en tirées sont proposées
    Pour les accords main gauche E, Em, E7, C, seules les touches en poussé sont proposées
    Pour les accords main gauche G et F, les deux numéros de touches sont proposées lorsqu'elles existes
    Les notes altérées (sauf F#) ne sont pas proposées car trop de plan de claviers différents existent
    Pour la note G, les deux propositions sont faites sur le premier et deuxième rang

  Après le passage du plugin, il reste donc à faire le ménage pour supprimer les numéros de touches en trop
  pour les accords F et G et sur les notes G main droite

  Description version v1.03 :
  - pour limiter le travail du plugin, il est possible de sélectionner les mesures à traiter.
  - sans sélection, le plugin travaille sur toute la partition sauf la dernière portée.
  - la dernière portée n'est pas traitée car elle est sencée être en clé de Fa avec des Basses et des Accords.
  - pour traiter quand même la dernière portée, il suffit de la sélectionner.
  Description version v1.04 :
  - propose une tablature sur une ou deux lignes
  - propose de n'afficher qu'une seule alternative lorsque des notes existent sous plusieurs touches
  - propose de tirer ou de pousser les G et les F ou d'indiquer les deux possibilités
  - propose de privilégier le rang de G ou celui de C ou de favoriser le jeu en croisé
  - propose un clavier 2 rangs ou 3 rangs (plan castagnari)
  - utiliser les accords A B Bb C D E f G G# pour déterminer le sens

  Description version v1.05
  - Modification de la structure des plans de clavier main droite et main gauche pour admettre plusieurs type d'accordéons
  - Adaptation du formulaire de choix en conséquence
  - Adaptation du code pour prendre en compte les nouvelles structures
  - Mémorisation des parametres dans un fichier DiatonicTab.json
  - Ajouts plans de claviers
  - Traduction en anglais
  - Traitement des accords enrichis
  - Nettoyage du code
  - Tablatures CADB, Corgeron et DES (Rémi Sallard)

  Description version v1.06
  - Externalisation des plans de clavier, 1 par fichier
  - 20200326 v1.06.03.001 Gestion des accords main droite corgeron et cadb
  - v1.06.03.20200327 : Travail sur le design de la boite de dialogue
  - v1.06.03.20200328.0924 : Travail sur le design de la boite de dialogue
  - v1.06.03.20200328.1117 : Ajout des offsetY dans les parametres
  - v1.06.03.20200328.1230 : SUpression du clavier en A/D
  - v1.06.03.20200328.1739 : Mise au points de détails
  - v1.06.03.20200329.1023 : Modification de l'ordre d'affichage des options à l'écran
  - V1.06.03.20200402.1646 : Mise de la langue dans les parametres
  - V1.06.03.20200406.1051 : Choix de souligner ou pas les Tirés dans le modèle C.A.D.B.
  - V1.06.04.20200427.1259 : Ajout de l'option Placer D.E.S. au dessous de la Portée
  - V1.06.05;20200623.0945 : Correction méthode Corgeron

  ----------------------------------------------------------------------------*/
import QtQuick 2.2
import MuseScore 3.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import QtQuick.Layouts 1.1
import FileIO 3.0
import QtQuick.Dialogs 1.2

MuseScore {


//-----------------------------------------------------

//   description: qsTr("Tablatures pour accordéon diatonique")
   description: qsTr("Tablatures for diatonic accordion")

   menuPath: "Plugins.DiatonicTab.Tablature"
   requiresScore: true
   version: "1.06.05.20200623.0945"
   pluginType: "dialog"

   property int margin: 10

   width:  500
   height: 640

//---------------------------------------------------------------
// Parameters, global variables for the whole plugin. These data are
// stored in the DiatonicTab.json file. They are here
// here in case the json file is missing
//---------------------------------------------------------------
property var parametres: {
         "offsetY" : { "CADBT" : 5.85,
                       "CADBP" : 5.85,
                       "DES":0,
                       "CorgeronAlt": 2.25,
                       "CorgeronC": 2.25,
                       "CorgeronG": 2.25,
                      },           // Shift down in score
         "sensFa"  : 3,               // 1 Fa Drawn  / 2 Fa Pushed / 3 Fa in both ways
         "sensSol" : 3,               // 1 Sol Drawn  / 2 Sol Pushed / 3 Sol in both ways
         "typeJeu" : 3,               // 1 C privileged  / 2 G privileged / 3 Crossplay
         "typePossibilite": 2,        // 2 Show all possibilities  / 1 display only one possibility
         "typeTablature":  "DES",     // tablature CADB or Corgeron or DES (single line)
         "placerDESDessous" : 1,      // The DES tabmature goes below the staff
         "clavierMD"  : {},           // Contents of the right-hand keyboard
         "clavierMG" : {},            // Contents of the left-hand keyboard
         "soulignerTireCADB" : 1,     // Underline drawn in C.A.D.B.
         //-----------------------------------------------------
         // Set here the parametres.language : FR = French, EN = English
         "lang": "FR",                // User language
}
//---------------------------------------------------------------
// File descriptors: parameters and keyboards
//---------------------------------------------------------------
// JSON files for storing parameters
FileIO {
        id: myParameterFile
        source: homePath() + "/DiatonicTab.json"
        onError: console.log(msg)
}
// RH_*.keyboard files for the right-hand keyboard
// LH_*.keyboard files for the left-hand keyboard
FileIO {
    // JSON format files for memorizing keyboards
    id: fichierClavier
    onError: console.log(msg)
}
// ------------------------------------------------------
// Dialog box for choosing the right-hand keyboard file
// ------------------------------------------------------
FileDialog {
      id: fileDialogClavierMD
      title: qsTr("RH Keyboard")
      folder: shortcuts.documents + "/MuseScore3/plugins/DiatonicTab/"
      nameFilters: [ "Layout (RH_*.keyboard)", "All files (*)" ]
      selectedNameFilter: "Layout (RH_*.keyboard)"
      selectExisting: true
      selectFolder: false
      selectMultiple: false
        onAccepted: {
                debug("OK : " + fileUrl)
                if (fileUrl.toString().indexOf("file:///") != -1)
                  fichierClavier.source = fileUrl.toString().substring(fileUrl.toString().charAt(9) === ':' ? 8 : 7)
                else
                  fichierClavier.source = fileUrl
                // Reading the keyboard plan
                parametres.clavierMD = JSON.parse(fichierClavier.read())
                // Updates the display in the dialog
                textDescriptionClavierMD.text = parametres.clavierMD.description
        }
        onRejected: {
            console.log("Canceled")
            Qt.quit()
        }
}
// ------------------------------------------------------
// Dialog box for choosing the left-hand keyboard file
// ------------------------------------------------------
FileDialog {
        id: fileDialogClavierMG
        title: qsTr("LF Keyboard")
        folder: shortcuts.documents + "/MuseScore3/plugins/DiatonicTab/"
        nameFilters: [ "Layout (LH_*.keyboard)", "All files (*)" ]
        selectedNameFilter: "Layout (LH_*.keyboard)"
        selectExisting: true
        selectFolder: false
        selectMultiple: false
          onAccepted: {
                  debug("OK : " + fileUrl)
                  if (fileUrl.toString().indexOf("file:///") != -1)
                    fichierClavier.source = fileUrl.toString().substring(fileUrl.toString().charAt(9) === ':' ? 8 : 7)
                  else
                    fichierClavier.source = fileUrl
                  // Reading the keyboard plan
                  parametres.clavierMG = JSON.parse(fichierClavier.read())
                  // Updates the display in the dialog
                  textDescriptionClavierMG.text = parametres.clavierMG.description
          }
          onRejected: {
              console.log("Canceled")
              Qt.quit()
          }
  }

// -------------------------------------------------------------------
// Description of the dialog window
//--------------------------------------------------------------------
 GridLayout {
      id: 'mainLayout'
      anchors.fill: parent
      anchors.margins: 10
      columns: 3

Label {
     Layout.columnSpan : 3
     width: parent.width
     elide: Text.ElideNone
     horizontalAlignment: Qt.AlignCenter
     font.bold: true
     font.pointSize: 16
     text:  (parametres.lang == "FR") ? qsTr("Tablatures pour accordéons diatoniques") :
                             qsTr("Tablature for diatonic accordion")
      }

//------------------------------------------------
// Type of accordion and keyboard layout RIGHT hand
//------------------------------------------------
GroupBox {
  Layout.columnSpan : 3
  Layout.fillWidth: true
  width: parent.width
  title : (parametres.lang == "FR") ? qsTr("Choix des claviers : ") :
                           qsTr("Diatonic keyboard : ")
   GridLayout {
       height: parent.height
       anchors.fill: parent
       width: parent.width
       columns: 3

      Label {
           horizontalAlignment: Qt.AlignRigth
           text:  (parametres.lang == "FR") ? qsTr("Clavier MD utilisé : ") :
                                   qsTr("Used RH Keyboard : ")
            }
      // -----------------------------------------------
      // Right hand keyboard choice
      Text {
                 id : textDescriptionClavierMD
                 elide : Text.ElideNone
                 text : ""
                 font.bold: true
      }
      Button {
            id: buttonChoixFichierClavier
            Layout.alignment: Qt.AlignRight
            isDefault: false
            text: (parametres.lang == "FR") ? qsTr(" Changer Clavier MD ") :
                                    qsTr(" Change RH Keyboard ")
            onClicked: {
                // Choice of the keyboard among the RH_*.keyboard files
                fileDialogClavierMD.open()
            }
      }
      // -----------------------------------------------
      // -----------------------------------------------
      // Choice of Left Hand keyboard
      Label {
             horizontalAlignment: Qt.AlignRigth
             text:  (parametres.lang == "FR") ? qsTr("Clavier MG utilisé : ") :
                                     qsTr("Used LH Keyboard  : ")
              }
      Text {
             id : textDescriptionClavierMG
             elide : Text.ElideNone
             text : ""
             font.bold: true
      }
      Button {
            id: buttonChoixFichierClavierMG
            Layout.alignment: Qt.AlignRight
            isDefault: false
            text:  (parametres.lang == "FR") ? qsTr(" Changer Clavier MG ") :
                                    qsTr(" Change LH Keyboard ")
            onClicked: {
                // Choice of keyboard from LH_*.keyboard files
                fileDialogClavierMG.open()
            }
      }
    }   // GridLayout
}  // Keyboard Maps GroupBox
// -----------------------------------------------

//-------------------------------------------------------------------------
// Floor measurement direction 1 = pulled / 2 = pushed / 3 = both ways
//-------------------------------------------------------------------------
GroupBox {
    title:  (parametres.lang=="FR")?qsTr("Sens du soufflet pour passages en Sol"):
                         qsTr("Bellows direction for G measures")
    Layout.columnSpan : 3
    Layout.fillWidth: true
    RowLayout {
        ExclusiveGroup { id: tabPositionGroupSOL }
        RadioButton {
            text: (parametres.lang=="FR")?qsTr("Dans les 2 sens"):qsTr("Push AND Pull")
            checked: (parametres.sensSol==3)
            exclusiveGroup: tabPositionGroupSOL
            onClicked : {
              parametres.sensSol = 3
            }
        }
        RadioButton {
            text: (parametres.lang=="FR")?qsTr("Privilégier le tiré"):qsTr("Pull priority")
            checked: (parametres.sensSol==1)
            exclusiveGroup: tabPositionGroupSOL
            onClicked : {
              parametres.sensSol = 1
            }
          }
        RadioButton {
            text: (parametres.lang=="FR")?qsTr("Privilégier le poussé"):qsTr("Push priority")
            exclusiveGroup: tabPositionGroupSOL
            checked: (parametres.sensSol==2)
            onClicked : {
              parametres.sensSol = 2
            }
        }
    } // RowLayout
} // GroupBox of the Ground direction choice
//------------------------------------------------
// Direction of F bars 1 = pulled / 2 = pushed / 3 = both ways
//------------------------------------------------
GroupBox {
    title: (parametres.lang=="FR")?qsTr("Sens du souffler pour les passages en Fa"):
                        qsTr("Bellows direction for F measures")
     Layout.columnSpan : 3
     Layout.fillWidth: true
    RowLayout {
        ExclusiveGroup { id: tabPositionGroupFA }
        RadioButton {
            text:(parametres.lang=="FR")?qsTr("Dans les 2 sens"):qsTr("Push AND Pull")
            checked: (parametres.sensFa==3)
            exclusiveGroup: tabPositionGroupFA
            onClicked : {
              parametres.sensFa = 3
            }
        }
        RadioButton {
            text: (parametres.lang=="FR")?qsTr("Privilégier le tiré"):qsTr("Pull priority")
            checked: (parametres.sensFa==1)
            exclusiveGroup: tabPositionGroupFA
            onClicked : {
              parametres.sensFa = 1
            }

        }
        RadioButton {
            text: (parametres.lang=="FR")?qsTr("Privilégier le poussé"):qsTr("Push priority")
            checked: (parametres.sensFa==2)
            exclusiveGroup: tabPositionGroupFA
            onClicked : {
              parametres.sensFa = 2
            }
        }
    } // RowLayout
} // Fa direction choice groupbox
//------------------------------------------------
// Single or double option
//------------------------------------------------
GroupBox {
    title: (parametres.lang=="FR")?qsTr("Lorsque plusieurs touches correspondent à une même note"):
                        qsTr("When several keys correspond to a same note")
    Layout.columnSpan : 3
    Layout.fillWidth: true
    RowLayout {
        ExclusiveGroup { id: tabPositionGroupPossibilite }
        RadioButton {
            text:(parametres.lang=="FR")?qsTr("Afficher toutes les possibilités"):
                              qsTr("Show all possibilities")
            checked : (parametres.typePossibilite==2)
            exclusiveGroup: tabPositionGroupPossibilite
            onClicked : {
              parametres.typePossibilite = 2
            }
        }
        RadioButton {
            text:(parametres.lang=="FR")?qsTr("N'afficher qu'une seule possibilité"):
                              qsTr("Show only one possibility")
            checked : (parametres.typePossibilite==1)
            exclusiveGroup: tabPositionGroupPossibilite
            onClicked : {
              parametres.typePossibilite = 1
            }
        }
    } // RowLayout
} // GroupBox Number of possibilities
//------------------------------------------------
// Meaning type of game 1 = C / 2 = G / 3 = Crossed
//------------------------------------------------
GroupBox {
    title: (parametres.lang=="FR")?qsTr("Jeu Tiré/Poussé ou Croisé"):qsTr("Crossed or Push/Pull playing")
    Layout.columnSpan : 3
    Layout.fillWidth: true
    RowLayout {

        ExclusiveGroup { id: tabPositionGroupCroise }
        RadioButton {
            text: (parametres.lang=="FR")?qsTr("Jeu en croisé"):qsTr("Crossed playing")
            exclusiveGroup: tabPositionGroupCroise
             checked: (parametres.typeJeu==3)
            onClicked : {
              parametres.typeJeu = 3
            }
        }
        RadioButton {
            text:(parametres.lang=="FR")?qsTr("Privilégier rang 1"):qsTr("Row #1 priority")
            checked: (parametres.typeJeu==1)
            exclusiveGroup: tabPositionGroupCroise
            onClicked : {
              parametres.typeJeu = 1
            }
        }
        RadioButton {
            text:(parametres.lang=="FR")?qsTr("Privilégier rang 2"):qsTr("Row #2 priority")
            checked: (parametres.typeJeu==2)
            exclusiveGroup: tabPositionGroupCroise
            onClicked : {
              parametres.typeJeu = 2
            }
        }
    } // RowLayout
} // GroupBox Game type
//------------------------------------------------
// Type of tablature
//------------------------------------------------
GroupBox {
    Layout.columnSpan : 3
    Layout.fillWidth: true
    title: (parametres.lang=="FR")?qsTr("Tablature : "):
                        qsTr("Tablature : ")
    GridLayout {
        Layout.fillWidth: true
        width:parent.width
        columns : 3
        ExclusiveGroup { id: tabPositionGroupNbLigne }
        GroupBox {
              title: " "
              width:parent.width
              Layout.fillWidth: true
              anchors.left: parent.left
              anchors.top: parent.top
              ColumnLayout {
                    width:parent.width
                    Layout.fillWidth: true
                    RadioButton {
                          text:(parametres.lang=="FR")?qsTr("C.A.D.B."):
                                            qsTr("C.A.D.B.")
                          exclusiveGroup: tabPositionGroupNbLigne
                          checked : (parametres.typeTablature =="CADB")
                          onClicked : {
                            parametres.typeTablature = "CADB"
                          }
                    }
                    Label {
                          width: parent.width
                          wrapMode: Label.Wrap
                          text:  (parametres.lang == "FR") ? qsTr("Décalage Y ligne P :") :
                                                  qsTr("Y Offset P line   :")
                    }
                    TextField {
                          width:parent.width
                          Layout.fillWidth: true
                          id : inputTextoffsetYCADBP
                          text : (parametres.offsetY.CADBP)?parametres.offsetY.CADBP:0
                          horizontalAlignment: Qt.AlignRight
                          onEditingFinished : {
                              parametres.offsetY.CADBP = text
                          }
                    }
                    Label {
                          width: parent.width
                          wrapMode: Label.Wrap
                          text:  (parametres.lang == "FR") ? qsTr("Décalage Y ligne T :") :
                                                  qsTr("Y Offset T line   :")
                    }
                    TextField {
                          width:parent.width
                          Layout.fillWidth: true
                          id : inputTextoffsetYCADBT
                          text : parametres.offsetY.CADBT
                          horizontalAlignment: Qt.AlignRight
                          onEditingFinished : {
                              parametres.offsetY.CADBT = text
                          }
                    }
                    CheckBox {
                        id: cbSoulignerTireCADB
                        width:parent.width
                        Layout.fillWidth: true
                        Layout.columnSpan : 2
                        text: (parametres.lang=="FR")? qsTr("Souligner les Tirer"):
                                            qsTr("Underline Pull")
                        checked: (parametres.soulignerTireCADB == "1")
                    }
              }   // RowLayout CADB
        } // GroupBox CADB
        GroupBox {
            title: " "
            width:parent.width
            Layout.fillWidth: true
            anchors.top: parent.top
            ColumnLayout {
                   width:parent.width
                   Layout.fillWidth: true
                   RadioButton {
                          text:(parametres.lang=="FR")?qsTr("Corgeron"):
                                            qsTr("Corgeron")
                          exclusiveGroup: tabPositionGroupNbLigne
                          checked : (parametres.typeTablature =="Corgeron")
                          onClicked : {
                             parametres.typeTablature = "Corgeron"
                          }
                    }
                    Label {
                          width: parent.width
                          wrapMode: Label.Wrap
                          text:  (parametres.lang == "FR") ? qsTr("Décalage ligne Alt :") :
                                                  qsTr("Y Offset Alt line  :")
                    }
                    TextField {
                          horizontalAlignment: Qt.AlignRight
                          width:parent.width
                          Layout.fillWidth: true
                          id : inputTextoffsetYCorgeronAlt
                          text : parametres.offsetY.CorgeronAlt
                          onEditingFinished : {
                               parametres.offsetY.CorgeronAlt = text
                          }
                    }
                    Label {
                          width: parent.width
                          wrapMode: Label.Wrap
                          text:  (parametres.lang == "FR") ? qsTr("Décalage ligne C :") :
                                                  qsTr("Y Offset C line  :")
                    }
                    TextField {
                          horizontalAlignment: Qt.AlignRight
                          width:parent.width
                          Layout.fillWidth: true
                          id : inputTextoffsetYCorgeronC
                          text : parametres.offsetY.CorgeronC
                          onEditingFinished : {
                               parametres.offsetY.CorgeronC = text
                          }
                    }
                    Label {
                          width: parent.width
                          wrapMode: Label.Wrap
                          text:  (parametres.lang == "FR") ? qsTr("Décalage ligne G :") :
                                                  qsTr("Y Offset G line  :")
                    }
                    TextField {
                          horizontalAlignment: Qt.AlignRight
                          width:parent.width
                          Layout.fillWidth: true
                          id : inputTextoffsetYCorgeronG
                          text : parametres.offsetY.CorgeronG
                          onEditingFinished : {
                               parametres.offsetY.CorgeronG = text
                          }
                    }
              } // RowLayout
        } // GroupBox
        GroupBox {
              anchors.right: parent.right
              width:parent.width
              Layout.fillWidth: true
              anchors.top: parent.top
              title: " "
              ColumnLayout {
                  Layout.fillWidth: true
                  width:parent.width
                  RadioButton {
                        width:parent.width
                        text:(parametres.lang=="FR")?qsTr("D.E.S."):
                                          qsTr("D.E.S.")
                        checked : (parametres.typeTablature=="DES")
                        exclusiveGroup: tabPositionGroupNbLigne
                        onClicked : {
                            parametres.typeTablature = "DES"
                        }
                  }
                  // OffsetY
                  Label {
                      Layout.fillWidth: true
                      width: parent.width
                      wrapMode: Label.Wrap
                      text:  (parametres.lang == "FR") ? qsTr("Position (décalage Y) :") :
                                              qsTr("Position (Y offset)   :")
                  }
                  TextField {
                        width:parent.width
                        horizontalAlignment: Qt.AlignRight
                        Layout.fillWidth: true
                        id : inputTextoffsetYDES
                        text : parametres.offsetY.DES
                        onEditingFinished : {
                             parametres.offsetY.DES = text
                        }
                  }
                  CheckBox {
                      id: cbPlacerDESDessous
                      width:parent.width
                      Layout.fillWidth: true
                      Layout.columnSpan : 2
                      text: (parametres.lang=="FR")? qsTr("Numéros sous la portée"):
                                          qsTr("Number under staff")
                      checked: (parametres.placerDESDessous == "1")
                  }
              } // RowLayout
          } // GroupBox DES
    } // GridLayout of the tablature type choice
  } // GroupBox

//-----------------------------------------------
RowLayout {
  Layout.fillWidth: true
  width: parent.width
  Layout.alignment: Qt.AlignCenter
  Layout.columnSpan: 3

   Button {
         id: okButton
         isDefault: true
         text: qsTr("OK")
         onClicked: {
            // Remember settings for next time
            memoriseParametres()
            // Write the tablature
            curScore.startCmd()
            doTablature()
            curScore.endCmd()
            // end of sequence
            Qt.quit();
         }
      }
   Button {
         id: cancelButton
         text: (parametres.lang=="FR")?qsTr( "Annuler"):qsTr("Cancel")
         onClicked: {
           memoriseParametres()
           Qt.quit();
         }
      }
    }
    Label {
      id: labelVersion
      Layout.columnSpan: 3
      Layout.alignment: Qt.AlignCenter
      text : "v"+ version + " " + parametres.lang
      MouseArea {
          anchors.fill: parent
          onClicked: { parametres.lang = (parametres.lang == "FR")? "EN" : "FR"
                      labelVersion.text = "v"+ version + " " + parametres.lang }
      }
    }
    // Rectangle {
    // width: 10; height: 10
    // color: "green"
    // //anchors.fill: parent
    // text: "FR"
    // MouseArea {
    //     anchors.fill: parent
    //     onClicked: { parametres.lang = (parametres.lang == "FR")? "EN" : "FR"
    //                 labelVersion.text = "v"+ version + " " + parametres.lang }
    // }
// }
  } // GridLayout


function debug(message) {
  if (true) {
    console.log(message) 
  }
}

function addElement(cursor, element) {
  debug("Ajout de l'élément: " + element.name + "(" + element.text + ")")
  cursor.add(element)
}

// -----------------------------------------------------------------------------
// Parameter memory function
// This function replaces the elements of the dialog box in the Parameters
// which is not always done when clicking OK or Cancel
// -----------------------------------------------------------------------------
function memoriseParametres(){
  parametres.offsetY.CADBP     = inputTextoffsetYCADBP.text
  parametres.offsetY.CADBT     = inputTextoffsetYCADBT.text
    parametres.offsetY.DES      = inputTextoffsetYDES.text
    parametres.offsetY.CorgeronAlt = inputTextoffsetYCorgeronAlt.text
    parametres.offsetY.CorgeronC = inputTextoffsetYCorgeronC.text
    parametres.offsetY.CorgeronG = inputTextoffsetYCorgeronG.text
    parametres.soulignerTireCADB = (cbSoulignerTireCADB.checkedState == Qt.Checked) ? "1" : "0"
  parametres.placerDESDessous = (cbPlacerDESDessous.checkedState == Qt.Checked)? "1" : "0"
    myParameterFile.write(JSON.stringify(parametres).replace(/,/gi ,",\n"))

}
// ------------------------------------------------------------------------------
// function addKey(cursor, notes, chord)
// This function adds the number of the key to be pressed according to the left hand chord
// Enter: cursor positioned at the place where the key number must be inserted
//              notes to be processed, this function only processes the entire CHORD
//              the last left hand chord encountered to choose between pulled and pushed when possible
// If the note does not exist in pushing but it exists in pulling, this one is proposed whatever the chord (A, F, F#)
// and reciprocally
// The criteria defined by the user in the dialog box are used here
//------------------------------------------------------------------------------
 function addTouche(cursor, notes, accord) {

     var textPousse, textTire, textAlt
     var numNote                // Counter on the notes of the CHORD
     var tabRangC = []          // For the Corgeron system, we create 3 Rank tables
     var tabRangG = []
     var tabRangAlt = []
     var ia = 0, ic = 0, ig = 0 // and three indexes to place the key numbers
     var tabRangT = []          // For the CADB system, we create 2 tables
     var tabRangP = []
     var iT = 0, iP = 0         // and two indexes to place the key numbers

     // ------------------------------------------------------------------------
     // Loop on each note of the chord
     // ------------------------------------------------------------------------
     for (numNote = 0;  numNote < notes.length; numNote ++){
        var note = notes[numNote]
        // ------------------------------------------------------------------------
        // Choice between STAFF_TEXT and LYRICS: If tablature on 2 lines, LYRICS, otherwise STAFF
        //------------------------------------------------------------------------------
        if (parametres.typeTablature=="DES") {
          textPousse =  newElement(Element.STAFF_TEXT)
          textTire   =  newElement(Element.STAFF_TEXT)
          textAlt    =  newElement(Element.STAFF_TEXT)
          if (parametres.placerDESDessous == "1") {
            textPousse.placement = Placement.BELOW;
            textTire.placement = Placement.BELOW;
            textAlt.placement = Placement.BELOW;
          } else {
            textPousse.placement = Placement.ABOVE;
            textTire.placement = Placement.ABOVE;
            textAlt.placement = Placement.ABOVE;
          }
        } else {
          textPousse =  newElement(Element.LYRICS)
          textTire   =  newElement(Element.LYRICS)
          textAlt    =  newElement(Element.LYRICS)
        }

        textPousse.text = textTire.text = textAlt.text = ""

        // ------------------------------------------------------------------------
        // Cleaning of enriched chords, transformation into basic chord
        //------------------------------------------------------------------------------
        // Removal of bass in Am/C notation
           accord = accord.split("\/")[0]
        // Turn flats into sharps
           var transBemol = { "AB":"G#","BB":"A#","CB":"B","DB":"C#","EB":"D#","FB":"E","GB":"F#" }
           if (accord.match(/^[A-G]B/)) accord = transBemol[accord[0]+"B"]
        // Supression de M m - sus add 7 6 9 etc dans Am7(b5)
           if (!accord.match("#")) accord = accord[0]
           else accord = accord[0] + "#"

        // ------------------------------------------------------------------------

        // ------------------------------------------------------------------------
        // Manufacture by calculating the name of the note from C0 to B9
        //------------------------------------------------------------------------------
        // note.pitch contains the note number in the MuseScore universe.
         var noteNames = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
         var octave = Math.floor(note.pitch / 12) - 1      // octave number
         var noteName = noteNames[note.pitch % 12]         // Look for the note in the table of note names
         if (noteName.match("#"))                          // Adds the octave to this note name (keeping the #)
               noteName = noteName[0] + octave + noteName[1]
          else
               noteName += octave
        // ------------------------------------------------------------------------

        // ------------------------------------------------------------------------
        // Retrieval of the number of diato keys to display according to the chosen keyboard model
        //------------------------------------------------------------------------------
        var noBouton = parametres.clavierMD[noteName]
        if (!noBouton) noBouton = ""
        // ------------------------------------------------------------------------

        // ------------------------------------------------------------------------
        // Variable for Pull/Push play
        var indexDoubleSens = 0

        // ------------------------------------------------------------------------
        // Finding Pulled and Pushed Buttons, Key Number Formatting
        // the noButton variable can contain :
        // xP or xT for a single X key in Pull or Push
        // xP/xT or xT/xP for two keys in Pull Push
        // xP/yP or xT/yT for two push-pull keys
        // xP/yP/zT for three keys, etc...
        var tabBouton = noBouton.split("/")             // Cutting according to slashes
        var i = 0
        for (i = 0 ; i < tabBouton.length ; i++) {
               if (tabBouton[i].match("P")) textPousse.text += tabBouton[i].replace("P","") + "/"
               if (tabBouton[i].match("T")) textTire.text   += tabBouton[i].replace("T","") + "/"
        }
        if (textPousse.text.match("/$"))  textPousse.text = textPousse.text.substr(0,textPousse.text.length -1)
        if (textTire.text.match("/$"))  textTire.text = textTire.text.substr(0,textTire.text.length -1)
        // ------------------------------------------------------------------------

        // ------------------------------------------------------------------------
        // Game type cross, pull/push
        // If the game is crossed, we take into account the chords to choose the direction
        // If the game is pushed, we do not take into account the chords
           switch (parametres.typeJeu) {

           case 3 : // Crossplay, agreements are taken into account
                if (parametres.clavierMG["Tire"].match("-"+accord+"-"))
        					if (textTire.text != "")
        						textPousse.text    = "";

                if (parametres.clavierMG["Pousse"].match("-"+accord+"-"))
        					if (textPousse.text != "")
        						textTire.text      = "";

                 if (parametres.clavierMG["2sens"].match("-"+accord+"-"))
                 {
                    if (accord.match(/F/i)) {
                      switch (parametres.sensFa) {
                        case 1 :          // Fa (Sol/Do)  pull only
                               if (textTire.text != "") textPousse.text = ""; // remove pushed text
                        break
                        case 2 :          // Fa (Sol/Do)  push only
                               if (textPousse.text != "") textTire.text = "";  // remove of pulled text
                        break
                        case 3 : // Fa in both sensSol
                        break
                      }
                    }
                    if (accord.match(/G/i))
                    {
                      switch (parametres.sensSol) {
                        case 1 :          // Sol (Sol/Do)  pull only
                               if (textTire.text != "") textPousse.text      = ""; // remove pushed text
                        break
                        case 2 :          // Sol (Sol/Do)  push only
                                if (textPousse.text != "") textTire.text      = "";  // remove of pulled text
                        break
                        case 3 :          // Sol in both sensSol

                        break
                      }
                    }
                 }

           break;
           // pull game pushed on row 2 (from C on a GC)
           case 2 :
                 //If double possibility, we only keep rank 2
                 if (textTire.text.match("/"))
                    textTire.text = textTire.text.split("/")[(textTire.text.match(/'$/))?1:0]
	         if (textPousse.text.match("/"))
	                textPousse.text = textPousse.text.split("/")[(textPousse.text.match(/'$/))?1:0]
	         if (textTire.text.match("'")  && (!textPousse.text.match("'"))) textPousse.text = ""
	         if (textPousse.text.match("'")  && (!textTire.text.match("'"))) textTire.text = ""
	         indexDoubleSens = (textTire.text.match(/\/.*'$/) || textPousse.text.match(/\/.*'$/)) ? 1 : 0
           break;
           // pulled game pushed on row 1 (from G on a GC)
           case 1 :
                 //If double possibility drawn, we only keep the rank of 1 (no ')
                 if (textTire.text.match("/"))
                        textTire.text   = textTire.text.split("/")[(textTire.text.match(/'$/))?0:1]

                 //If double possibility in pushing, we only keep the rank of 1 (no ')
                 if (textPousse.text.match("/"))
	                textPousse.text = textPousse.text.split("/")[(textPousse.text.match(/'$/))?0:1]


	         if (!(textTire.text.match(".'"))  && (textPousse.text.match(".'"))) textPousse.text = ""

	         if ( !(textPousse.text.match(".'"))  && (textTire.text.match(".'"))) textTire.text = ""

	         indexDoubleSens = (textTire.text.match(/\/.*'$/) || textPousse.text.match(/\/.*'$/)) ? 1 : 0

           break;
           }
         //End of the "game type" switch
         // ------------------------------------------------------------------------

        // ------------------------------------------------------------------------
	   // Management of double possibilities for duplicate notes on the keyboard
	   // If we want only one possibility, we keep only the first one defined in the table of keys
	   if (parametres.typePossibilite == 1) {
	        if (textTire.text.match("/"))   textTire.text   = textTire.text.split("/")[indexDoubleSens]
	        if (textPousse.text.match("/")) textPousse.text = textPousse.text.split("/")[indexDoubleSens]
	   }
    // ------------------------------------------------------------------------

    // ------------------------------------------------------------------------
        // Management of the positioning according to the number of lines of the tablature
	   switch(parametres.typeTablature) {
	         case "Corgeron":
	               var tabPossibiliteTire   = textTire.text.split("/")
	               var tabPossibilitePousse = textPousse.text.split("/")
	               // Distribution between Alt, C and G ranks
                 // the ia, ic and ig indexes are set to 0 at the very start of the function
                 // the arrRangG arrRangC and arrRangAlt arrays are initialized at the start of the function
	               var i
	               for (i = 0 ; i < tabPossibiliteTire.length ; i++) {
	                   if (tabPossibiliteTire[i] != "")
	                   if (tabPossibiliteTire[i].match("''"))
                       tabRangAlt[ia++] = "<u>" + tabPossibiliteTire[i].substr(0,tabPossibiliteTire[i].length -2) + "</u>"
	                   else if (tabPossibiliteTire[i].match("'"))
                       tabRangC[ic++] = "<u>" + tabPossibiliteTire[i].substr(0,tabPossibiliteTire[i].length -1) + "</u>"
	                   else
                     tabRangG[ig++] = "<u>" + tabPossibiliteTire[i] + "</u>"
	               }

	               for (i = 0 ; i < tabPossibilitePousse.length ; i++) {
	                   if (tabPossibilitePousse[i] != "")
	                   if (tabPossibilitePousse[i].match("''"))
	                     tabRangAlt[ia++] = tabPossibilitePousse[i].substr(0,tabPossibilitePousse[i].length -2)
	                   else if (tabPossibilitePousse[i].match("'"))
	                     tabRangC[ic++] = tabPossibilitePousse[i].substr(0,tabPossibilitePousse[i].length -1)
	                   else
	                        tabRangG[ig++] = tabPossibilitePousse[i]
	               }
                 // When we reach the last note of the chord, we break down the information
                 if (numNote == notes.length-1){
                  textTire.autoplace = textPousse.autoplace = textAlt.autoplace = false
	                 textAlt.offsetY     = parametres.offsetY.CorgeronAlt
                   textPousse.offsetY  = parametres.offsetY.CorgeronC
                   textTire.offsetY    = parametres.offsetY.CorgeronG
	                 textAlt.verse = 0
	                 textAlt.text = tabRangAlt[0]
  	               for (i = 1 ; i < tabRangAlt.length ; i++) {
  	                   if (textAlt[i] != "") textAlt.text += "/" + tabRangAlt[i]
  	               }
  	               if (textAlt.text != "") {
	                   textAlt.text = textAlt.text.replace(/(.*)''(.*)/g,"$1$2")
	                   textAlt.text = textAlt.text.replace(/(.*)'(.*)/g,"$1$2")
  	               }
  	               textPousse.text = tabRangC[0]
  	               textPousse.verse = 1
  	               for (i = 1 ; i < tabRangC.length ; i++) {
  	                   if (tabRangC[i] != "") textPousse.text += "/" + tabRangC[i]
  	               }
  	               if (textPousse.text != "") {
  	                   textPousse.text = textPousse.text.replace(/(.*)''(.*)/g,"$1$2")
  	                   textPousse.text = textPousse.text.replace(/(.*)'(.*)/g,"$1$2")
  	               }
  	               textTire.text = tabRangG[0]
  	               textTire.verse = 2
  	               for (i = 1 ; i < tabRangG.length ; i++) {
  	                   if (tabRangG[i] != "") textTire.text += "/" + tabRangG[i]
  	               }
  	               if (textTire.text != "") {
  	                   textTire.text = textTire.text.replace(/(.*)''(.*)/g,"$1$2")
  	                   textTire.text = textTire.text.replace(/(.*)'(.*)/g,"$1$2")
  	               }
                 }
	          break
            case "CADB":                  // Collective of Diatonic Accordions of Brittany
                tabRangT[iT++] = textTire.text
                tabRangP[iP++] = textPousse.text
                // When it is the last note of the chord, we stack all the notes to display in textTire.text and textPousse.text
                if (numNote == notes.length-1){
                    textTire.text = tabRangT[0]
                    for (var i = 1; i<tabRangT.length; i++)
                      if (tabRangT[i] !== "")  textTire.text += "/" +tabRangT[i]

                    textPousse.text = tabRangP[0]
                    for (var i = 1; i<tabRangP.length; i++)
                      if (tabRangP[i] !== "") textPousse.text += "/"+tabRangP[i]
                    textPousse.verse = 0
                    textTire.verse   = 1
                    textTire.offsetY    = parametres.offsetY.CADBT
                    textPousse.offsetY  = parametres.offsetY.CADBP
                    textTire.autoplace  = textPousse.autoplace = false
                    if (parametres.soulignerTireCADB == "1")
                      textTire.text = "<u>"+textTire.text+"</u>"
                }
            break
            case "DES":                         // Rémi Sallard Style
              	    textTire.offsetY   = textPousse.offsetY  = parametres.offsetY.DES
	                  textTire.autoplace = textPousse.autoplace = true
                    // Adds numbers to auto-placed tablature
                    if (textAlt.text !=  "") cursor.add(textAlt)
                    if (textTire.text !=  "") {
                      textTire.text = "<u>" + textTire.text + "</u>"
                      cursor.add(textTire)
                    }
                    if (textPousse.text != "") cursor.add(textPousse)
            break
        }
        // ------------------------------------------------------------------------
      }   // End of the loop for(numNote = 0; numNote<notes.length; numNote++)
        // ------------------------------------------------------------------------
        // Finally, we display the number of the key in the score
        // for the Corgeron and CADB tablatures, the DES have already been added
        if (parametres.typeTablature != "DES"){
          if (textAlt.text !=  "") cursor.add(textAlt)
          if (textTire.text !=  "") {
              // textTire.text = "<u>" + textTire.text + "</u>"
              cursor.add(textTire)
          }
          if (textPousse.text != "") cursor.add(textPousse)
        }
        // ------------------------------------------------------------------------
}


// ---------------------------------------------------------------------
// doTablature function
//
// Main function called by the click of the OK button
//----------------------------------------------------------------------
function doTablature() {

      var myScore = curScore,                  // Current score
          cursor = myScore.newCursor(),        // Make a slider to move through the measures
          startStaff,                          // Start of score or start of selection
          endStaff,                            // End of partition or end of selection
          endTick,                             // Number of the last element of the score or of the selection
          staff = 0,                           // staff number in score
          accordMg,                            // Determines if we are in Push or Pull when possible
          fullScore = false;                   // Entire score or selection

      //Look for the staves, we will not work on the last staff (usually bass clef, basses and chords)
      // in the case of DES tablature, all staves minus 1 are processed
      // in the Corgeron or CADB case, only staff 1 is processed and staff 2 is written (if it exists)
      var nbPortees = (parametres.typeTablature == "DES") ? myScore.nstaves : (myScore.nstaves >= 2) ? 2 : 1

      // do not agree left hand a priori
      accordMg = "zzz"

      // ---------------------------------------------------------------------
      // Loop on each of the staves except the last one if there are several
      // ---------------------------------------------------------------------
      do {
            cursor.voice    =  0                          // If CADB or Corgeron, voice 1 of staff 1
            cursor.staffIdx =  staff

            // Management of a selection or the processing of the entire partition

            cursor.rewind(Cursor.SELECTION_START)           // rewind to start of selection
            if (!cursor.segment) { // no selection
                  fullScore = true;
                  startStaff = 0;                           // starts at the first bar
                  endStaff = curScore.nstaves - 1;          // and ends at the last
            } else {
                  startStaff = cursor.staffIdx;             // starts at the beginning of the selection
                  cursor.rewind(2);                         // goes behind the last segment and sets tick = 0
                  if (cursor.tick === 0) {                  // this happens when the selection contains the last measure
                       endTick = curScore.lastSegment.tick + 1;
                  } else {
                      endTick = cursor.tick;
                  }
                 endStaff = cursor.staffIdx;
            }

            if (fullScore) {                          // if no selection
                  cursor.rewind(Cursor.SCORE_START)   // rewind to start of score
             } else {                                 // if selection
                 cursor.rewind(Cursor.SELECTION_START)// rewind to start of selection
             }

             // -------------------------------------------------------------------
             // Loop for each element of the current staff or selection
             // -------------------------------------------------------------------
             while (cursor.segment && (fullScore || cursor.tick < endTick))  {
                    var aCount = 0;

                    // Search for left hand chords (like Am or Em or E7 ...)
                    var annotation = cursor.segment.annotations[aCount];
                    while (annotation) {
                           if (annotation.type == Element.HARMONY){
                             if (annotation.text != "%")
                                accordMg = annotation.text.toUpperCase()
                           }
                           annotation = cursor.segment.annotations[++aCount];
                    }

                  // If the cursor points to one or more notes played simultaneously
                  if (cursor.element && cursor.element.type == Element.CHORD) {
                        var notes = cursor.element.notes
                        // We send all the notes of the CHORD
                            addTouche(cursor, notes, accordMg)
                  } // end if CHORD

                  cursor.next() //Next item

             } // end of while cursor.segment and (fullScore || cursor.tick < endTick)

             staff+=1 // Next staff

      } while ((parametres.typeTablature == "DES")
            && (staff < nbPortees-1)
            && fullScore)  // end of the for each staff unless selected

        // Reminder: we do not process the last staff which is probably in bass clef,
        // with basses and chords. To process it anyway, simply select it

  }   // End of the doTablature function
  //-------------------------------------------------------
  // Plugin initialization
  //-------------------------------------------------------
     onRun: {
debug("parametres.lang : " + parametres.lang)
          if (!curScore) Qt.quit();   // If no current partition, plugin exit
          if (typeof curScore === 'undefined')  Qt.quit();

          //------------------------------------------------------------------------------
          // Reading the parameter file
          //------------------------------------------------------------------------------
          parametres = JSON.parse(myParameterFile.read())
          //------------------------------------------------------------------------------
          textDescriptionClavierMD.text = parametres.clavierMD.description
          textDescriptionClavierMG.text = parametres.clavierMG.description
          inputTextoffsetYCADBT.text     = parametres.offsetY.CADBT
          inputTextoffsetYCADBP.text     = parametres.offsetY.CADBP
          inputTextoffsetYDES.text      = parametres.offsetY.DES
          inputTextoffsetYCorgeronAlt.text = parametres.offsetY.CorgeronAlt
          inputTextoffsetYCorgeronC.text = parametres.offsetY.CorgeronC
          inputTextoffsetYCorgeronG.text = parametres.offsetY.CorgeronG
          cbSoulignerTireCADB.checked = (parametres.soulignerTireCADB == "1")
          cbPlacerDESDessous.checked = (parametres.placerDESDessous == "1")

          //------------------------------------------------------------------------------
      }
}  // MuseScore
