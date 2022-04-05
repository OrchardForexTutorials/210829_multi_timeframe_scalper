/*

	Trade_mql4.mqh
	Copyright 2021, Orchard Forex 
	https://orchardforex.com 

*/

#property copyright "Copyright 2021, Orchard Forex"
#property link      "https://orchardforex.com"
#property version   "1.00"
#property strict

//	Some return code definitions
enum ENUM_TRADE_RETCODES {
	TRADE_RETCODE_INVALID		=	10013,	//	Invalid request
};

enum ENUM_ORDER_TYPE_TIME {
	ORDER_TIME_GTC,
};
	
struct MqlTradeResult { 
   uint     retcode;          // Operation return code 
   ulong    deal;             // Deal ticket, if it is performed 
   ulong    order;            // Order ticket, if it is placed 
   double   volume;           // Deal volume, confirmed by broker 
   double   price;            // Deal price, confirmed by broker 
   double   bid;              // Current Bid price 
   double   ask;              // Current Ask price 
   string   comment;          // Broker comment to operation (by default it is filled by description of trade server return code) 
   uint     request_id;       // Request ID set by the terminal during the dispatch  
   uint     retcode_external; // Return code of an external trading system 
};
  
class CTrade {

private:

protected:

   int					m_magic;                // expert magic number

   MqlTradeResult    m_result;               // result data

   void              ClearStructures(void);

public:

   CTrade();
   ~CTrade();

   void              SetExpertMagicNumber(const int magic)     { m_magic=magic;                    }

   bool					PositionOpen(const string symbol,const ENUM_ORDER_TYPE order_type,const double volume,
                             			const double price,const double sl,const double tp,const string comment="");

};

CTrade::CTrade() {

	
}

CTrade::~CTrade() {

}

bool	CTrade::PositionOpen(const string symbol,const ENUM_ORDER_TYPE order_type,const double volume,
                          const double price,const double sl,const double tp,const string comment) {

//--- clean
   ClearStructures();

//--- check
   if (order_type!=ORDER_TYPE_BUY && order_type!=ORDER_TYPE_SELL) {
		m_result.retcode=TRADE_RETCODE_INVALID;
      m_result.comment="Invalid order type";
		return(false);
	}

   return (OrderSend(symbol, order_type, volume, price, 0, sl, tp, comment, m_magic)>0);

}

void CTrade::ClearStructures(void) {
   ZeroMemory(m_result);
}

