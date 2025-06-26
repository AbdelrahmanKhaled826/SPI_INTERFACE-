# 📦 SPI Interface with RAM – Verilog Implementation

## 📘 Overview
This project implements a Serial Peripheral Interface (SPI) protocol in Verilog to communicate with a simple RAM module, providing full-duplex communication between a master and slave device. It simulates a real-world embedded memory communication system with write/read capabilities over SPI.

The implementation includes:

  ✅ SPI Master

  ✅ SPI Slave with FSM

  ✅ RAM Memory

  ✅ Top-level Wrapper

  ✅ Fully documented Testbench with multiple scenarios

## 🧠 Top-level design wrapper

![image](https://github.com/user-attachments/assets/b612b42c-5e38-4f2e-8fc1-d0ed0f4198fd)

## 📁 Project Structure

    spi-ram-verilog/
    │
    ├── RTL/
    │   ├── spi_master.v
    │   ├── spi_slave.v
    │   ├── RAM.v
    │   ├── spi_wrapper.v
    │
    ├── Test bench/
    │   └── spi_wrapper_tb.v   ← Testbench file
    │
    ├── README.md              ← You are here
    └── spi.pdf

## 🧰 Tools Used

🛠️ Verilog HDL

🧪 QuestaSim 2021 – Simulation

🎛️ Vivado 2018 – Synthesis and RTL Verification

## 🚦 How It Works

Write Operation:

    00 + 8-bit Addr → Select write address

    01 + 8-bit Data → Write data to selected address

Read Operation:

    10 + 8-bit Addr → Select read address

    11 + 8-bit Dummy → Read data from selected address

Each command is passed as a 10-bit word from the master to the slave.

## 📑 Testbench Summary
Each test iteration includes:

1. Write Address

2. Write Data

3. Read Address

4. Read Data (with expected verification)

✅ Pass/Fail results printed to simulation log.

## 🧾 SPI Command Table

| Command Type | Control Bits | Function                |
|--------------|---------------|-------------------------|
| Write Addr   | `00`          | Set RAM write address   |
| Write Data   | `01`          | Write data to address   |
| Read Addr    | `10`          | Set RAM read address    |
| Read Data    | `11`          | Output data from address |

## 🧠 Master FSM States
  | **State**      | **Code**    | **Description**                                                                                     |
  |----------------|-------------|-----------------------------------------------------------------------------------------------------|
  | `IDLE`         | `3'b000`    | Waits for a rising edge of `start`. Clears control signals and initializes `mosi_reg`.              |
  | `WAIT_SREADY`  | `3'b001`    | Waits for the slave to assert `sready` before initiating communication.                            |
  | `ASSERT_SS`    | `3'b010`    | Asserts `SS̅` low and enables `SCLK` to start sending data to the slave.                            |
  | `SEND_MOSI`    | `3'b011`    | Shifts out the 10-bit word on `MOSI`. If command is `READ_DATA` (prefix `11`), transitions to `RECV_MISO`. |
  | `RECV_MISO`    | `3'b100`    | Shifts in 8-bit data from slave via `MISO`. Waits for `miso_valid`.                                |
  | `END`          | `3'b101`    | Finalizes transaction. Sets `done`, deasserts `SS̅`, and resets counters.                           |


![image](https://github.com/user-attachments/assets/f83457df-3ef3-4d82-ad11-9abc668d80aa)

## 🧠 SPI Slave FSM (Finite State Machine)

This FSM controls the behavior of the SPI slave during communication. It transitions based on the `SS̅` signal and command bits received via `MOSI`.

| **State**     | **Code**     | **Description**                                                                                                                                 |
|---------------|--------------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| `IDLE`        | `5'b00001`   | Waits for `SS̅` to go low (slave select active). All control and data signals are cleared.                                                     |
| `CHK_CMD`     | `5'b00010`   | Captures the most significant bit (MSB) to determine whether the command is a write or read.                                                   |
| `WRITE`       | `5'b00100`   | Shifts in 8 bits of data (after MSB) and stores it. Ends by asserting `rx_valid`.                                                              |
| `READ_ADDR`   | `5'b01000`   | Shifts in 8-bit read address from master and asserts `rx_valid`. Sets `addr_stored` flag for future data retrieval.                           |
| `READ_DATA`   | `5'b10000`   | Sends out 8 bits from `tx_data` to master via `MISO`. Asserts `miso_valid` while shifting. Clears `addr_stored` when done.                     |


![image](https://github.com/user-attachments/assets/86758cae-3725-492f-a16e-7c3257b95bd8)


## 📷 Screenshots / Waveforms 

![image](https://github.com/user-attachments/assets/dc8cfe7d-890a-4506-8dab-950501fe52c1)


The comparison between the expected output and the actual output shows perfect alignment, confirming the correctness and functionality.

## ✅ Test Cases

| **Case** | **Operation**   | **Command (10-bit)** | **Description**                            | **Expected Output** | **Observed Output** | **Status** |
|----------|-----------------|----------------------|--------------------------------------------|---------------------|---------------------|------------|
| 1        | Write Address    | 00_00010000          | Store address 0x10 in RAM                  | Done = 1            | Done asserted       | ✅ Passed  |
| 2        | Write Data       | 01_10101010          | Write data 0xAA to address 0x10            | Done = 1            | Done asserted       | ✅ Passed  |
| 3        | Read Address     | 10_00010000          | Set read address to 0x10                   | Done = 1            | Done asserted       | ✅ Passed  |
| 4        | Read Data        | 11_00000000          | Read data from address 0x10                | 0xAA                | 0xAA                | ✅ Passed  |

 
## 📘Elaborated Design
![image](https://github.com/user-attachments/assets/cf694e6e-619e-451f-8285-d7eb535171a3)


## 🏁 How to Run
1. Open QuestaSim or another simulator.

2. Compile all RTL and TB files.

3. Run spi_wrapper_tb.

4. View waveforms and logs to verify SPI transactions.

## 🙋‍♂️ Author
🔍Name: Abdelrahman Khaled

🔍Gmail: abdokhaled1712002@gmail.com

🔍LinkedIn: https://www.linkedin.com/in/abdelrahman-khaled-7012ba251/





