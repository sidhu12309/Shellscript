ls /tmp/testfile
if [ $? -eq 0 ]; then
  echo "Command successful"
else
  echo "Command failed"
fi
