library(xgboost) # booster = gbtree for forest, booster = gblinear for GLM based regression
#Xgboost default uses all available cores
#gamma[default=0][range: (0,Inf)], regularization. gamma = 5 is moderate to high. Start w 0, check training test 
    # accuracy, then increase up to 5 or higher if needed. Too high a tree depth may not work with a high gamma.
#max_depth[default=6][range: (0,Inf)], probably up this a bit
#subsample[default=1][range: (0,1)], % data available to tree, usually between (0.5-0.8)
#colsample_bytree[default=1][range: (0,1)], # of features available to each tree, 

#dtrain <- xgb.DMatrix(data = train$data, label=train$label) # puts data in format for Xgboost

# spring 
xgb.salspring<-list(data = as.matrix(salspring.tbl[,2:6]),label = as.matrix(salspring.tbl[,1]))
forest.salspring<-xgboost(data = xgb.salspring.list$data, label = xgb.salspring.list$label, nrounds = 10, max_depth = 8,
                          subsample = 0.6)
xgb.yelspring<-list(data = as.matrix(yelspring.tbl[,2:6]),label = as.matrix(yelspring.tbl[,1]))
forestpred.spring.ten<-predict(forest.salspring,xgb.yelspring$data)
cor(forestpred.spring.ten,xgb.salspring.list$label)

# summer