## scripts/client/debug.sh
#!/bin/sh
echo "Starting debug checks..."
echo "Java version:"
java -version
echo "X11 setup:"
echo $DISPLAY
echo "User info:"
id
echo "Current directory:"
pwd
echo "Home directory:"
ls -la $HOME
echo "Java executable location:"
which java
echo "Python executable location:"
which python3
echo "NoVNC setup:"
ls -la /app/noVNC/utils/
echo "Supervisor config:"
ls -la /etc/supervisor/conf.d/
ls -la /etc/supervisor.d/
echo "Testing X11 connection:"
xauth info || echo "xauth not configured"
echo "Debug checks complete."