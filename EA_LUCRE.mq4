//+------------------------------------------------------------------+
//|                                                     EA_LUCRE.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+

#property copyright "Martingale Scalping EA customized By Victor@ 2021"
#property link      "http://www.mql4.com"
#property description "Use TF M5 currency EUR/USD"

string Use_TradeAgain = "If => TRUE,EA will trade again,If => FALSE => EA will Off";
bool TradeAgain = TRUE;
string Use_Loop = "Example = 10,EA will trader for 10 Laps";
int Loop = 10000;
int LoopNo;
extern int StartTrade = 0;
extern int EndTrade = 24; // 12-24
double Lots = 0.01;
double SL = 0.0;
extern double TP = 4.0; // 3.0-4.0
double Distance = 2.0;
extern double Multiplier = 1.5; // 1.5-2.0
int MaxOrder = 20;
double Slippage = 3.0;
double LotsDecimal = 2.0;
int MagicNumber = 163991;
string EA_Comment = "EA LUCRE";
double TPPrice;
double OrderPrice;
double BuyPrice;
double SellPrice;
datetime time = 0;
int OrderNo = 0;
double OrderLot;
int index = 0;
int TotalOrder;
bool HasOrder;
bool HasBuyOrder = FALSE;
bool HasSellOrder = FALSE;
int OpenOrderStatus;
bool CanOpenOrder = FALSE;
bool Gi_312 = FALSE;
double Pip;
double TotalHistoryLot;
double MoneyPerLot = 7.0;
extern double Deposit = 50.0;
extern double MaxStopLoss = 10.0;
double TotalProfit = 0.0

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int init() {
    if(Digits == 3 || Digits == 5)
        Pip = 10.0 * Point;
    else
        Pip = Point;
    return (0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int deinit() {
    ObjectsDeleteAll();
    return (0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start() {
    double closeShift2;
    double closeShift1;
    double totalLot;
    InitDisplay();
    EADisplay();
    if(AllowBotTrade()) {
        if(time == Time[0])
            return (0);
        time = Time[0];
        TotalOrder = CountOpeningOrder();
        if(TotalOrder == 0)
            HasOrder = FALSE;
        for(index = OrdersTotal() - 1; index >= 0; index--) {
            if(OrderSelect(index, SELECT_BY_POS, MODE_TRADES)) {
                if(!IsBotOrder())
                    continue;

                if(OrderType() == OP_BUY) {
                    HasBuyOrder = TRUE;
                    HasSellOrder = FALSE;
                    break;
                }
                if(OrderType() == OP_SELL) {
                    HasBuyOrder = FALSE;
                    HasSellOrder = TRUE;
                    break;
                }
            }
        }
        if(TotalOrder > 0 && TotalOrder <= MaxOrder) {
            RefreshRates();
            BuyPrice = GetOrderPrice(OP_BUY);
            SellPrice = GetOrderPrice(OP_SELL);
            if(HasBuyOrder && BuyPrice - Ask >= Distance * Pip)
                CanOpenOrder = TRUE;
            if(HasSellOrder && Bid - SellPrice >= Distance * Pip)
                CanOpenOrder = TRUE;
        }
        if(TotalOrder < 1) {
            HasSellOrder = FALSE;
            HasBuyOrder = FALSE;
            CanOpenOrder = TRUE;
        }
        if(CanOpenOrder) {
            BuyPrice = GetOrderPrice(OP_BUY);
            SellPrice = GetOrderPrice(OP_SELL);
            if(HasSellOrder) {
                OrderLot = CalculateLotOrder(OP_SELL);
                OrderNo = TotalOrder;
                if(OrderLot > 0.0) {
                    RefreshRates();
                    OpenOrderStatus = OpenOrder(1, OrderLot, Slippage, EA_Comment + "-" + OrderNo);
                    if(OpenOrderStatus < 0) {
                        Print("Error: ", GetLastError());
                        return (0);
                    }
                    SellPrice = GetOrderPrice(OP_SELL);
                    CanOpenOrder = FALSE;
                    Gi_312 = TRUE;
                }
            } else {
                if(HasBuyOrder) {
                    OrderLot = CalculateLotOrder(OP_BUY);
                    OrderNo = TotalOrder;
                    if(OrderLot > 0.0) {
                        OpenOrderStatus = OpenOrder(0, OrderLot, Slippage, EA_Comment + "-" + OrderNo);
                        if(OpenOrderStatus < 0) {
                            Print("Error: ", GetLastError());
                            return (0);
                        }
                        BuyPrice = GetOrderPrice(OP_BUY);
                        CanOpenOrder = FALSE;
                        Gi_312 = TRUE;
                    }
                }
            }
        }
        if(CanTrade()) {
            if(LoopNo < Loop && TradeAgain) {
                if(CanOpenOrder && TotalOrder < 1) {
                    closeShift2 = iClose(Symbol(), 0, 2);
                    closeShift1 = iClose(Symbol(), 0, 1);
                    if((!HasSellOrder) && (!HasBuyOrder)) {
                        OrderNo = TotalOrder;
                        if(closeShift2 > closeShift1) {
                            OrderLot = CalculateLotOrder(OP_SELL);
                            if(OrderLot > 0.0) {
                                OpenOrderStatus = OpenOrder(1, OrderLot, Slippage, EA_Comment + "-" + OrderNo);
                                LoopNo++;
                                if(OpenOrderStatus < 0) {
                                    Print(OrderLot, "Error: ", GetLastError());
                                    return (0);
                                }
                                BuyPrice = GetOrderPrice(OP_BUY);
                                Gi_312 = TRUE;
                            }
                        } else {
                            OrderLot = CalculateLotOrder(OP_BUY);
                            if(OrderLot > 0.0) {
                                OpenOrderStatus = OpenOrder(0, OrderLot, Slippage, EA_Comment + "-" + OrderNo);
                                LoopNo++;
                                if(OpenOrderStatus < 0) {
                                    Print(OrderLot, "Error: ", GetLastError());
                                    return (0);
                                }
                                SellPrice = GetOrderPrice(OP_SELL);
                                Gi_312 = TRUE;
                            }
                        }
                    }
                }
            }
        }
        TotalOrder = CountOpeningOrder();
        OrderPrice = 0;
        totalLot = 0;
        for(index = OrdersTotal() - 1; index >= 0; index--) {
            if(OrderSelect(index, SELECT_BY_POS, MODE_TRADES))
                if(!IsBotOrder())
                    continue;
            if(IsBotOrder()) {
                if(OrderType() == OP_BUY || OrderType() == OP_SELL) {
                    OrderPrice += OrderOpenPrice() * OrderLots();
                    totalLot += OrderLots();
                }
            }
        }
        if(TotalOrder > 0)
            OrderPrice = NormalizeDouble(OrderPrice / totalLot, Digits);
        if(Gi_312) {
            for(index = OrdersTotal() - 1; index >= 0; index--) {
                if(OrderSelect(index, SELECT_BY_POS, MODE_TRADES))
                    if(!IsBotOrder())
                        continue;
                if(IsBotOrder()) {
                    if(OrderType() == OP_BUY) {
                        TPPrice = OrderPrice + TP * Pip;
                        HasOrder = TRUE;
                    }
                }
                if(IsBotOrder()) {
                    if(OrderType() == OP_SELL) {
                        TPPrice = OrderPrice - TP * Pip;
                        HasOrder = TRUE;
                    }
                }
            }
        }
        if(!Gi_312)
            return (0);
        if(HasOrder != TRUE)
            return (0);
        for(index = OrdersTotal() - 1; index >= 0; index--) {
            if(OrderSelect(index, SELECT_BY_POS, MODE_TRADES))
                if(!IsBotOrder())
                    continue;
            if(IsBotOrder())
                if(OrderModify(OrderTicket(), OrderPrice, OrderStopLoss(), TPPrice, 0, White))
                    Gi_312 = FALSE;
        }
    }
    return (0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateLotOrder(int cmd) {
    double lot; 
    lot = NormalizeDouble(Lots * MathPow(Multiplier, OrderNo), LotsDecimal);
    if(AccountFreeMarginCheck(Symbol(), cmd, lot) <= 0.0)
        return (-1);
    if(GetLastError() == 134/* NOT_ENOUGH_MONEY */)
        return (-2);
    return (lot);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountOpeningOrder() {
    int count = 0;
    for(index = OrdersTotal() - 1; index >= 0; index--) {
        if(OrderSelect(index, SELECT_BY_POS, MODE_TRADES))
            if(!IsBotOrder())
                continue;
        if(IsBotOrder())
            if(OrderType() == OP_SELL || OrderType() == OP_BUY)
                count++;
    }
    return (count);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OpenOrder(int caseNo, double orderLot, int orderSlippage, string orderComment) {
    int ticket = 0;
    for(index = 0; index < 100; index++) {
        RefreshRates();
        ticket = OrderSend(Symbol(), caseNo == 0 ? OP_BUY : OP_SELL, orderLot, caseNo == 0 ? Ask : Bid, orderSlippage, 0, 0, orderComment, MagicNumber, 0, CLR_NONE);
        int error = GetLastError();
        if(error == 0/* NO_ERROR */)
            break;
        if(!((error == 4/* SERVER_BUSY */ || error == 137/* BROKER_BUSY */ || error == 146/* TRADE_CONTEXT_BUSY */ || error == 136/* OFF_QUOTES */)))
            break;
        Sleep(5000);
    }
    return (ticket);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetOrderPrice(int cmd) {
    double orderOpenPrice;
    int orderTicket;
    int tempTicket = 0;
    for(index = OrdersTotal() - 1; index >= 0; index--) {
        if(OrderSelect(index, SELECT_BY_POS, MODE_TRADES))
            if(!IsBotOrder())
                continue;
        if(IsBotOrder() && OrderType() == cmd) {
            orderTicket = OrderTicket();
            if(orderTicket > tempTicket) {
                orderOpenPrice = OrderOpenPrice();
                tempTicket = orderTicket;
            }
        }
    }
    return (orderOpenPrice);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateComms() {
    TotalHistoryLot = 0;
    double totalComms = 0;
    for(index = 0; index < OrdersHistoryTotal(); index++) {
        if(OrderSelect(index, SELECT_BY_POS, MODE_HISTORY))
            if(IsBotOrder())
                TotalHistoryLot += OrderLots();
    }
    totalComms = TotalHistoryLot * MoneyPerLot;
    return (totalComms);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateCurrentComms() {
    TotalHistoryLot = 0;
    double totalComms = 0;
    for(index = 0; index < OrdersTotal(); index++) {
        if(OrderSelect(index, SELECT_BY_POS, MODE_TRADES))
            if(IsBotOrder())
                TotalHistoryLot += OrderLots();
    }
    totalComms = TotalHistoryLot * MoneyPerLot;
    return (totalComms);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InitDisplay() {
    ObjectCreate("Original", OBJ_LABEL, 0, 0, 0);
    ObjectSetText("Original", " ", 10, "Arial Bold", Red);
    ObjectSet("Original", OBJPROP_CORNER, 2);
    ObjectSet("Original", OBJPROP_XDISTANCE, 200);
    ObjectSet("Original", OBJPROP_YDISTANCE, 10);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void EADisplay() {
    int PnLColor = Lime;
    if(AccountEquity() - AccountBalance() < 0.0)
        PnLColor = Red;
    string breakLine = "-------------------------------------------";
    Display("L01", "Arial", 9, 10, 10, Red, 1, breakLine);
    Display("L02", "Arial", 15, 10, 25, Lime, 1, "EA LUCRE");
    Display("L0i", "Arial", 12, 10, 45, Yellow, 1, "Scalping");
    Display("L03", "Arial", 9, 10, 60, Red, 1, breakLine);
    Display("L04", "Arial", 9, 10, 75, Lime, 1, "Account Company: " + AccountCompany());
    Display("L05", "Arial", 9, 10, 90, Lime, 1, "Name Server: " + AccountServer());
    Display("L06", "Arial", 9, 10, 105, Lime, 1, "Account Name: " + AccountName());
    Display("L07", "Arial", 9, 10, 120, Lime, 1, "Name Number: " + AccountNumber());
    Display("L08", "Arial", 9, 10, 135, Lime, 1, "Account Leverage: 1 " + AccountLeverage());
    Display("L09", "Arial", 9, 10, 150, Lime, 1, "Time Server: " + TimeToStr(TimeCurrent(), TIME_DATE | TIME_SECONDS));
    Display("L10", "Arial", 9, 10, 165, Lime, 1, "Spread: " + DoubleToStr(MarketInfo(Symbol(), MODE_SPREAD), 0));
    Display("L11", "Arial", 9, 10, 180, Lime, 1, "Account Balance: $ " + DoubleToStr(AccountBalance(), 2));
    Display("L12", "Arial", 9, 10, 195, Lime, 1, "Account Equity: $ " + DoubleToStr(AccountEquity(), 2));
    Display("L13", "Arial", 9, 10, 210, Lime, 1, "Order Total: " + DoubleToStr(OrdersTotal(), 0));
    Display("L14", "Arial", 9, 10, 390, PnLColor, 1, "Profit / Loss: $ " + DoubleToStr(AccountEquity() - AccountBalance(), 2));
    Display("L15", "Arial", 15, 10, 425, PnLColor, 1, " Commission: $ " + DoubleToStr(CalculateComms(), 2));
    ObjectCreate("j", OBJ_LABEL, 0, 0, 0);
    ObjectSet("j", OBJPROP_CORNER, 2);
    ObjectSet("j", OBJPROP_XDISTANCE, 10);
    ObjectSet("j", OBJPROP_YDISTANCE, 10);
    ObjectSetText("j", "EA LUCRE ", 15, "Arial", Lime);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Display(string name, string fontName, int fontSize, int x, int y, color cColor, int corner, string text) {
    if(ObjectFind(name) < 0)
        ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
    ObjectSetText(name, text, fontSize, fontName, cColor);
    ObjectSet(name, OBJPROP_CORNER, corner);
    ObjectSet(name, OBJPROP_XDISTANCE, x);
    ObjectSet(name, OBJPROP_YDISTANCE, y);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool AllowBotTrade() {
    if(IsTesting())
        return (TRUE);
    if(IsTradeAllowed())
        return (TRUE);
    return (FALSE);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsBotOrder() {
    return (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CanTrade() {
    // CalculateCurrentComms
    // Deposit = 50.0;
    // MaxStopLoss = 10.0;
    // TotalProfit = 0.0
    return (Hour() >= StartTrade && Hour() < EndTrade);
}