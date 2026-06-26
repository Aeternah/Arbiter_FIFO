# Arbiter FIFO — Round-Robin арбитр на Cyclone V

Проект реализует 4-канальный round-robin арбитр с FIFO-буферами на FPGA Altera Cyclone V в среде Quartus II 13.1.

## Структура проекта

```
arbiter_FIFO/
├── arbiter.sv        — round-robin арбитр
├── fifo.sv           — FIFO буфер (параметризованный)
├── top.sv            — верхний уровень: FIFO + арбитр + мультиплексор
├── top_cyclone.sv    — обёртка для платы: генератор запросов + LED индикация
├── tb_top.sv         — тестбенч для модуля top (4 мастера, backpressure)
├── tb_sim.sv         — тестбенч для симуляции top_cyclone
└── README.md
```

## Описание модулей

### `arbiter.sv`
Round-robin арбитр на `NUM_REQ` входов. Регистр `pointer` хранит индекс следующего кандидата после последнего выданного гранта. Комбинационная функция `round_robin()` выбирает первого активного запросчика начиная с `pointer`, после чего `pointer` сдвигается на позицию после победителя.

### `fifo.sv`
Синхронный FIFO с параметрами `WIDTH` и `DEPTH`. Детектирование заполненности и пустоты через расширенные указатели (extra bit). Интерфейс: `wr_valid/wr_ready` на запись, `rd_valid/rd_ready` на чтение.

### `top.sv`
Инстанцирует 4 FIFO и арбитр. Арбитр получает на вход `~fifo_empty` и выдаёт грант. Выбранный FIFO читается когда выходной интерфейс готов (`out_ready || !out_valid`). Выход регистровый для стабильной работы на Cyclone V.

### `top_cyclone.sv`
Обёртка для платы. Содержит генератор запросов на основе счётчика и LED индикацию.

**Параметры времени (важно!):**

| Параметр | Значение для платы | Значение для симуляции |
|---|---|---|
| `PERIOD` | `5_000_000` | `50` |

При частоте 50 МГц `PERIOD = 5_000_000` даёт период ~100 мс между запросами — смену LED видно глазом. Для симуляции используй `PERIOD = 50`, иначе симуляция займёт часы.

Перед синтезом для платы убедись что в файле стоит:
```systemverilog
localparam PERIOD = 5_000_000;  // для платы
```

Перед симуляцией замени на:
```systemverilog
localparam PERIOD = 50;  // для симуляции
```

### LED индикация на плате
Каждый светодиод соответствует одному мастеру:

| LED | Мастер | Данные |
|---|---|---|
| LED[0] | Master 0 | 0x01 |
| LED[1] | Master 1 | 0x02 |
| LED[2] | Master 2 | 0x03 |
| LED[3] | Master 3 | 0x04 |

Светодиоды загораются по очереди: LED0 → LED1 → LED2 → LED3 → LED0, подтверждая работу round-robin арбитра.

## Запуск симуляции в ModelSim

### 1. Открыть ModelSim вручную
```
Q:\quart-13.1\modelsim_ase\win32aloem\vsim.exe
```

### 2. В консоли ModelSim выполнить
```tcl
vlib work
vlog -sv "Q:/quart-13.1/my_arbiter_project/fifo.sv"
vlog -sv "Q:/quart-13.1/my_arbiter_project/arbiter.sv"
vlog -sv "Q:/quart-13.1/my_arbiter_project/top.sv"
vlog -sv "Q:/quart-13.1/my_arbiter_project/top_cyclone.sv"
vlog -sv "Q:/quart-13.1/my_arbiter_project/tb_sim.sv"
vsim work.tb_sim
```

### 3. Добавить сигналы и запустить
```tcl
add wave sim:/tb_sim/dut/u_top/u_arb/req
add wave sim:/tb_sim/dut/u_top/u_arb/pointer
add wave sim:/tb_sim/dut/u_top/u_arb/grant
add wave sim:/tb_sim/dut/in_valid_r
add wave sim:/tb_sim/dut/u_top/out_valid
add wave sim:/tb_sim/dut/u_top/out_data
add wave sim:/tb_sim/led
run -all
wave zoom full
```

### 4. Ожидаемый результат на waveform

```
pointer:    00 → 01 → 10 → 11 → 00 → ...
grant:    0001 → 0010 → 0100 → 1000 → 0001 → ...
out_data:   01 →  02 →  03 →  04 →  01 → ...
```

## Синтез и прошивка в Quartus

1. Убедиться что `PERIOD = 5_000_000` в `top_cyclone.sv`
2. Назначить пины через **Assignments → Pin Planner**
3. **Processing → Start Compilation**
4. **Tools → Programmer → Start**

## Параметры проекта

| Параметр | Значение |
|---|---|
| Целевое устройство | Altera Cyclone V |
| Тактовая частота | 50 МГц |
| Количество мастеров | 4 |
| Разрядность данных | 8 бит |
| Глубина FIFO | 16 слов |
| Тип арбитрации | Round-robin |
| Среда разработки | Quartus II 13.1 |
| Симулятор | ModelSim ALTERA STARTER EDITION 10.1d |