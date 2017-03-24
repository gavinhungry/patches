ARCH_DIR=$1
PKGSRC_DIR=$2

inform 'Updating icons'
cp hexchat.png $PKGSRC_DIR/data/icons/hexchat.png
cp empty.png $PKGSRC_DIR/data/icons/tray_fileoffer.png
cp empty.png $PKGSRC_DIR/data/icons/tray_highlight.png
cp empty.png $PKGSRC_DIR/data/icons/tray_message.png

cd ${ARCH_DIR}/abs/hexchat
