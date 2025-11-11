= Week 8: Python 고급 기능 및 통신
== 학습 목표
본 챕터에서는 다음을 학습한다: + TCP/IP 소켓 통신
+ OPC UA 프로토콜
+ Modbus 통신
+ 데이터베이스 연동
== TCP/IP 소켓 통신
=== 서버
```python
import socket
from threading import Thread
class EquipmentServer: def __init__(self, host: str = 'localhost', port: int = 5000): self.host = host
 self.port = port
 self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
 self.clients = []
 def start(self): self.socket.bind((self.host, self.port))
 self.socket.listen(5)
 print(f"Server listening on {self.host}: {self.port}")
 while True: client, address = self.socket.accept()
 print(f"Connection from {address}")
 self.clients.append(client)
 thread = Thread(target=self.handle_client, args=(client, ))
 thread.start()
 def handle_client(self, client: socket.socket): try: while True: data = client.recv(1024)
 if not data: break
 # 명령 처리
 command = data.decode('utf-8')
 response = self.process_command(command)
 client.send(response.encode('utf-8'))
 except Exception as e: print(f"Error: {e}")
 finally: client.close()
 def process_command(self, command: str) -> str: match command: case "GET_TEMP": return f"{self.get_temperature()}"
 case "GET_PRESSURE": return f"{self.get_pressure()}"
 case _: return "UNKNOWN_COMMAND"
```
=== 클라이언트
```python
class EquipmentClient: def __init__(self, host: str, port: int): self.host = host
 self.port = port
 self.socket = None
 def connect(self): self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
 self.socket.connect((self.host, self.port))
 print(f"Connected to {self.host}: {self.port}")
 def send_command(self, command: str) -> str: self.socket.send(command.encode('utf-8'))
 response = self.socket.recv(1024)
 return response.decode('utf-8')
 def disconnect(self): if self.socket: self.socket.close()
# 사용
client = EquipmentClient('localhost', 5000)
client.connect()
temp = client.send_command("GET_TEMP")
print(f"Temperature: {temp}°C")
```
=== Qt 통합
```python
from PySide6.QtNetwork import QTcpSocket, QAbstractSocket
class QtEquipmentClient(QObject): data_received = Signal(str)
 error_occurred = Signal(str)
 def __init__(self): super().__init__()
 self.socket = QTcpSocket()
 self.socket.connected.connect(self.on_connected)
 self.socket.readyRead.connect(self.on_ready_read)
 self.socket.errorOccurred.connect(self.on_error)
 def connect_to_host(self, host: str, port: int): self.socket.connectToHost(host, port)
 @Slot()
 def on_connected(self): print("Connected to server")
 @Slot()
 def on_ready_read(self): data = self.socket.readAll().data().decode('utf-8')
 self.data_received.emit(data)
 @Slot(QAbstractSocket.SocketError)
 def on_error(self, error): self.error_occurred.emit(self.socket.errorString())
 def send_command(self, command: str): self.socket.write(command.encode('utf-8'))
```
== OPC UA
=== 설치
```bash
pip install opcua
```
=== OPC UA 서버
```python
from opcua import Server
from datetime import datetime
class EquipmentOPCServer: def __init__(self): self.server = Server()
 self.server.set_endpoint("opc.tcp: //0.0.0.0: 4840/equipment/")
 # Namespace
 uri = "http: //example.org/equipment"
 self.idx = self.server.register_namespace(uri)
 # Objects
 objects = self.server.get_objects_node()
 self.equipment = objects.add_object(self.idx, "Equipment")
 # Variables
 self.temp_var = self.equipment.add_variable(self.idx, "Temperature", 0.0)
 self.temp_var.set_writable()
 self.pressure_var = self.equipment.add_variable(self.idx, "Pressure", 0.0)
 self.pressure_var.set_writable()
 def start(self): self.server.start()
 print("OPC UA server started")
 def stop(self): self.server.stop()
 def update_temperature(self, value: float): self.temp_var.set_value(value)
 def update_pressure(self, value: float): self.pressure_var.set_value(value)
```
=== OPC UA 클라이언트
```python
from opcua import Client
class EquipmentOPCClient: def __init__(self, url: str): self.client = Client(url)
 def connect(self): self.client.connect()
 print("Connected to OPC UA server")
 def disconnect(self): self.client.disconnect()
 def read_temperature(self) -> float: node = self.client.get_node("ns=2;s=Equipment.Temperature")
 return node.get_value()
 def write_temperature(self, value: float): node = self.client.get_node("ns=2;s=Equipment.Temperature")
 node.set_value(value)
 def subscribe(self, callback): handler = SubscriptionHandler(callback)
 sub = self.client.create_subscription(100, handler)
 node = self.client.get_node("ns=2;s=Equipment.Temperature")
 sub.subscribe_data_change(node)
class SubscriptionHandler: def __init__(self, callback): self.callback = callback
 def datachange_notification(self, node, val, data): self.callback(val)
```
== Modbus 통신
=== 설치
```bash
pip install pymodbus
```
=== Modbus TCP 클라이언트
```python
from pymodbus.client import ModbusTcpClient
class ModbusEquipmentClient: def __init__(self, host: str, port: int = 502): self.client = ModbusTcpClient(host, port)
 def connect(self): return self.client.connect()
 def disconnect(self): self.client.close()
 def read_temperature(self) -> float: # Holding Register 읽기
 result = self.client.read_holding_registers(address=0, count=1, slave=1)
 if not result.isError(): return result.registers[0] / 10.0 # 스케일링
 raise Exception("Read error")
 def write_setpoint(self, value: float): # Holding Register 쓰기
 scaled_value = int(value * 10)
 self.client.write_register(address=100, value=scaled_value, slave=1)
 def read_multiple(self, addresses: list[int]) -> list[float]: result = self.client.read_holding_registers(address=addresses[0], count=len(addresses), slave=1)
 if not result.isError(): return [r / 10.0 for r in result.registers]
 raise Exception("Read error")
```
=== Qt 통합
```python
class QtModbusClient(QObject): data_received = Signal(float)
 def __init__(self, host: str, port: int = 502): super().__init__()
 self.client = ModbusEquipmentClient(host, port)
 self.timer = QTimer()
 self.timer.timeout.connect(self.poll_data)
 def start_polling(self, interval_ms: int = 1000): self.client.connect()
 self.timer.start(interval_ms)
 def stop_polling(self): self.timer.stop()
 self.client.disconnect()
 @Slot()
 def poll_data(self): try: temp = self.client.read_temperature()
 self.data_received.emit(temp)
 except Exception as e: print(f"Error: {e}")
```
== 데이터베이스 연동
=== SQLite
```python
import sqlite3
from contextlib import contextmanager
class DatabaseManager: def __init__(self, db_path: str): self.db_path = db_path
 self.create_tables()
 @contextmanager
 def get_connection(self): conn = sqlite3.connect(self.db_path)
 try: yield conn
 conn.commit()
 except Exception: conn.rollback()
 raise
 finally: conn.close()
 def create_tables(self): with self.get_connection() as conn: conn.execute("""
 CREATE TABLE IF NOT EXISTS process_data (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp DATETIME, equipment_id TEXT, temperature REAL, pressure REAL, flow_rate REAL)
 """)
 def insert_data(self, data: ProcessData, equipment_id: str): with self.get_connection() as conn: conn.execute("""
 INSERT INTO process_data
 (timestamp, equipment_id, temperature, pressure, flow_rate)
 VALUES (?, ?, ?, ?, ?)
 """, (data.timestamp, equipment_id, data.temperature, data.pressure, data.flow_rate))
 def query_data(self, equipment_id: str, start_time: datetime, end_time: datetime) -> list[ProcessData]: with self.get_connection() as conn: cursor = conn.execute("""
 SELECT timestamp, temperature, pressure, flow_rate
 FROM process_data
 WHERE equipment_id = ?
 AND timestamp BETWEEN ? AND ?
 ORDER BY timestamp
 """, (equipment_id, start_time, end_time))
 return [
 ProcessData(timestamp=datetime.fromisoformat(row[0]), temperature=row[1], pressure=row[2], flow_rate=row[3])
 for row in cursor.fetchall()
 ]
```
=== PostgreSQL
```python
import psycopg2
from psycopg2.pool import SimpleConnectionPool
class PostgresManager: def __init__(self, host: str, database: str, user: str, password: str): self.pool = SimpleConnectionPool(minconn=1, maxconn=10, host=host, database=database, user=user, password=password)
 def insert_data(self, data: ProcessData, equipment_id: str): conn = self.pool.getconn()
 try: with conn.cursor() as cursor: cursor.execute("""
 INSERT INTO process_data
 (timestamp, equipment_id, temperature, pressure, flow_rate)
 VALUES (%s, %s, %s, %s, %s)
 """, (data.timestamp, equipment_id, data.temperature, data.pressure, data.flow_rate))
 conn.commit()
 finally: self.pool.putconn(conn)
 def close(self): self.pool.closeall()
```
== 통합 예제
=== 다중 통신 HMI
```python
class IntegratedHMI(QMainWindow): def __init__(self): super().__init__()
 # 통신 클라이언트
 self.tcp_client = QtEquipmentClient()
 self.opc_client = EquipmentOPCClient("opc.tcp: //localhost: 4840")
 self.modbus_client = QtModbusClient("localhost", 502)
 # 데이터베이스
 self.db = DatabaseManager("equipment.db")
 self.setup_ui()
 self.setup_connections()
 def setup_connections(self): # TCP
 self.tcp_client.data_received.connect(self.on_tcp_data)
 # Modbus
 self.modbus_client.data_received.connect(self.on_modbus_data)
 @Slot(str)
 def on_tcp_data(self, data: str): # TCP 데이터 처리
 print(f"TCP Data: {data}")
 @Slot(float)
 def on_modbus_data(self, value: float): # Modbus 데이터 처리 및 저장
 data = ProcessData(timestamp=datetime.now(), temperature=value, pressure=0.0, flow_rate=0.0)
 self.db.insert_data(data, "CVD-01")
```
== 실습 과제
=== 과제 1: TCP/IP 통신
+ 서버/클라이언트 구현
+ 명령 프로토콜 정의
+ Qt 통합
=== 과제 2: OPC UA 또는 Modbus
+ OPC UA 또는 Modbus 클라이언트 구현
+ 실시간 데이터 읽기
+ 주기적 폴링
=== 과제 3: 데이터베이스 로깅
+ SQLite/PostgreSQL 연동
+ 실시간 데이터 저장
+ 이력 데이터 조회 및 차트
== 요약
이번 챕터에서는 고급 통신을 학습했다: - TCP/IP 소켓 통신
- OPC UA 프로토콜
- Modbus 통신
- SQLite/PostgreSQL 데이터베이스
- Qt 통합
다음 챕터에서는 배포를 학습한다.
#pagebreak()