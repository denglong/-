 //
//  ShopCartController.m
//  KingProFrame
//
//  Created by JinLiang on 15/8/17.
//  Copyright (c) 2015年 king. All rights reserved.
//

#import "ShopCartController.h"
#import "CommodityDetailsViewController.h"
#import "TabBarController.h"
#import "CYCartInfoModel.h"
#import "Headers.h"
#import "CYCartGoodsModel.h"
#import "transferGoodsCell.h"
#import "LaunchViewController.h"

#define TABBARHEIGHT self.tabBarController.tabBar.frame.size.height

typedef enum{kGoodsNumDecade = -1,kGoodsNumKeep,kGoodsNumUp} goodsNumTrend;
@interface ShopCartController ()<reloadDelegate,ShopCartCellDelegate>
{
    UIView * noNetWork;
    UIView *deleteView;
    UIBarButtonItem *rightButton;
    NSString *mySettlement;
    UIButton *selectAll;     //编辑页面全选按钮
    BOOL toHome;
}
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraints;
/** 教学页 */
@property (nonatomic , strong) UIWindow *studyWindow;
/** 购物车信息汇总数组 */
@property (nonatomic , strong) NSMutableArray *infoArray;
/** 商品模型数组 */
@property (nonatomic , strong) NSMutableArray *goodsArray;

@end

@implementation ShopCartController

//@synthesize cartInfoArray;
//@synthesize editArray;
@synthesize settlementDic;
@synthesize goodsTableView;
@synthesize priceLabel,numLabel,diffPriceLabel;
@synthesize choseOkBtn;
@synthesize emptyView;


#define TYPE_EDITGOODS  @"1"//增删商品的数量
#define TYPE_DELECELL  @"2"//删掉整个商品

#pragma mark - 无网相关页面
//无网判断添加页面
- (BOOL)noNetwork {
    if ([self isNotNetwork]) {
        noNetWork = [NoNetworkView sharedInstance].view;
        noNetWork.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        [NoNetworkView sharedInstance].reloadDelegate =self;
        [self.view addSubview:noNetWork];
        
        return YES;
    }
    else
    {
        [noNetWork removeFromSuperview];
        return NO;
    }
}

// 点击重新加载按钮
-(void)reloadAgainAction{
    [super showHUD];
    [self requestShopInfo];
}


#pragma mark - 懒加载
- (NSMutableArray *)cartInfoArray
{
    if (_cartInfoArray == nil)
    {
        _cartInfoArray = [NSMutableArray array];
    }
    
    return _cartInfoArray;
}

- (NSMutableArray *)editArray
{
    if (_editArray == nil)
    {
        _editArray = [NSMutableArray array];
    }
    return _editArray;
}

- (NSMutableArray *)infoArray
{
    if (_infoArray == nil)
    {
        _infoArray = [NSMutableArray array];
    }
    
    return _infoArray;
}

- (NSMutableArray *)goodsArray
{
    if (_goodsArray == nil)
    {
        _goodsArray = [NSMutableArray array];
    }
    
    return _goodsArray;
}


#pragma mark - 控制器生命周期相关
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.emptyView.hidden=YES;
    // self.selecedAllBtn.hidden = YES;
    // 友盟统计
    [MobClick beginLogPageView:NSStringFromClass([self class])];
    if (![UserLoginModel isLogged]) {
        [[AppModel sharedModel] presentLoginController:self];
        return;
    }
    
    self.shopCartBtnView.hidden = YES;
    self.priceLabel.text=@"￥0.00";
    [self.choseOkBtn setTitle:@"  去下单(共0件)" forState:UIControlStateNormal];
    self.diffPriceLabel.text = @"会员共节省0元";
    
    [self requestShopInfo];
    
    [self setUpStudyview];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissSelf)
                                                 name:NOTIFICATION_LOGINCANCEL
                                               object:nil];
    if (_isOtherPush)
    {
        self.bottomConstraints.constant = 0;
    }
    else
    {
        self.bottomConstraints.constant = TABBARHEIGHT;
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:NSStringFromClass([self class])];
    [goodsTableView reloadData];
    
//    [self.studyWindow removeFromSuperview];
    self.studyWindow.hidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"购物车";
    [self showHUD];
    // Do any additional setup after loading the view from its nib.
    [MobClick event:Clik_ShopingCart];
    
    [self setUpGoodsTableview];
    _cloudClient=[CloudClient getInstance];
//    [self setUpNavigationBar];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (toHome == YES) {
        [self dismissSelf];
    }
} 

-(void)backAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - 初始化设置
- (void)setUpGoodsTableview
{
    self.view.backgroundColor=RGBACOLOR(245, 245, 241, 1);
    
    self.goodsTableView.backgroundColor=[UIColor clearColor];
    
    [self.goodsTableView registerNib:[UINib nibWithNibName:@"ShopCartTableViewCell"
                                                    bundle:nil]
                                    forCellReuseIdentifier:CYCartCellIdentifier];
    
    [self.goodsTableView registerNib:[UINib nibWithNibName:@"transferGoodsCell"
                                                    bundle:nil]
                                    forCellReuseIdentifier:CYTransferGoodsCellIdentifier];
    
    [self.goodsTableView registerNib:[UINib nibWithNibName:@"ShopCartTableViewCell"
                                                    bundle:nil]
                                    forCellReuseIdentifier:CYUnshelveGoodsCellIdentifier];
    
}


- (void)setUpNavigationBar
{
    UILabel *titleLable = [[UILabel alloc] init];
    titleLable.textColor = [UIColor_HEX colorWithHexString:@"#6a2906"];
    titleLable.text = @"购物车";
    [titleLable sizeToFit];
    self.navigationItem.titleView = titleLable;
    
    
//    rightButton = [[UIBarButtonItem alloc] initWithTitle:@"编辑"
//                                                   style:UIBarButtonItemStyleBordered
//                                                  target:self
//                                                  action:@selector(deleteShopAction:)];
//    
//    
//    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//    dict[NSForegroundColorAttributeName] = [UIColor_HEX colorWithHexString:@"#6a2906"];
//    [rightButton setTitleTextAttributes:dict forState:UIControlStateNormal];
}

- (void)disMissView
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)setUpStudyview
{
    
    //    NSLog(@"%@",[[NSUserDefaults standardUserDefaults] boolForKey:@"NEWVERSION"]);
    
    BOOL isNeedStudyView = [[NSUserDefaults standardUserDefaults] boolForKey:@"NEWVERSION"];
    
    if (isNeedStudyView == YES && [UserLoginModel isLogged])
    {
        UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        
        self.studyWindow = window;
        
        window.windowLevel = UIWindowLevelAlert;
        
        window.hidden = NO;
        
        window.backgroundColor = [UIColor blackColor];
        
        window.alpha = 0.8;
        
        // 中间图片
        UIImageView *leftSlide = [[UIImageView alloc] init];
        
        leftSlide.image = [UIImage imageNamed:@"购物车-教学页_07"];
        
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        
        CGFloat height = self.view.height *0.25;
        
        CGFloat leftSliderY = [UIScreen mainScreen].bounds.size.height * 0.5 - height;
        
        leftSlide.frame = CGRectMake(0, leftSliderY, width, height);
        
        [window addSubview:leftSlide];
        
        
        // 做滑可以删除文字
        UIImageView *slider = [[UIImageView alloc] init];
        
        slider.image = [UIImage imageNamed:@"购物车-教学页_03"];
        
        CGFloat sliderWidth =210;
        
        CGFloat sliderHeight = 45;
        
        CGFloat sliderX = (width - sliderWidth)*0.5;
        
        CGFloat sliderY = leftSlide.y - 50;
        
        slider.frame = CGRectMake(sliderX, sliderY, sliderWidth, sliderHeight);
        
        [window addSubview:slider];
        
        // 知道了按钮
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [button setImage:[UIImage imageNamed:@"首页-教学页_05"] forState:UIControlStateNormal];
        
        CGFloat buttonWidth  = 110;
        
        CGFloat buttonHeight = 60;
        
        CGFloat buttonX = ([UIScreen mainScreen].bounds.size.width - buttonWidth)*0.5;
        
        CGFloat buttonY= CGRectGetMaxY(leftSlide.frame) + 62;
        
        button.frame = CGRectMake(buttonX, buttonY, buttonWidth, buttonHeight);
        
        [window addSubview:button];
        
        [button addTarget:self
                   action:@selector(dismissStudyWindow)
         forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        self.studyWindow.hidden = YES;
    }
}

- (void)dismissStudyWindow
{
    [UIView animateWithDuration:0.5 animations:^{
        
        self.studyWindow.hidden = YES;
        
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"NEWVERSION"];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    }];
}




#pragma mark - 创建批量删除View
//- (void)addDeleteView {
//    
//    
//    // 全部删除整体view
//    deleteView = [[UIView alloc] initWithFrame:self.shopCartBtnView.frame];
//    deleteView.frame = CGRectMake(0, 0, viewWidth, self.shopCartBtnView.frame.size.height);
//    deleteView.backgroundColor = self.shopCartBtnView.backgroundColor;
//    deleteView.hidden = YES;
//    [self.shopCartBtnView addSubview:deleteView];
//    
//    // 选择所有商品按钮
//    selectAll = [[UIButton alloc] initWithFrame:CGRectMake(10, 0, 30, 30)];
//    selectAll.center = CGPointMake(20, deleteView.frame.size.height/2);
//    [selectAll setImage:UIIMAGE(@"cartSelect_icon_pressed") forState:UIControlStateNormal];
//    [selectAll setImage:UIIMAGE(@"cartSelect_icon") forState:UIControlStateSelected];
//    [deleteView addSubview:selectAll];
//    [selectAll addTarget:self action:@selector(selectAllAction:) forControlEvents:UIControlEventTouchUpInside];
//    
//    // 全选label
//    UILabel *selectLab = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, 60, 20)];
//    selectLab.center = CGPointMake(65, deleteView.frame.size.height/2);
//    selectLab.text = @"全选";
//    selectLab.font = [UIFont systemFontOfSize:15];
//    selectLab.textColor = [UIColor whiteColor];
//    [deleteView addSubview:selectLab];
//    
//    // 删除按钮
//    UIButton *deleteBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, viewWidth/4, 30)];
//    deleteBtn.center = CGPointMake(viewWidth - deleteBtn.frame.size.width/2 - 20, deleteView.frame.size.height/2);
//    deleteBtn.layer.cornerRadius = 15;
//    deleteBtn.backgroundColor = [UIColor_HEX colorWithHexString:@"#f57d6e"];
//    deleteBtn.titleLabel.font = choseOkBtn.titleLabel.font;
//    [deleteBtn setTitle:@"删除" forState:UIControlStateNormal];
//    [deleteBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [deleteView addSubview:deleteBtn];
//    [deleteBtn addTarget:self action:@selector(deleteDataAction:) forControlEvents:UIControlEventTouchUpInside];
//}

- (void)selectAllAction:(UIButton *)sender {
    if (sender.selected == YES) {
        sender.selected = NO;
        self.selectAllButton.selected = NO;
    }
    else
    {
        sender.selected = YES;
        self.selectAllButton.selected = YES;

    }
    [self futureGenerations:self.selecedAllBtn];
}

//批量删除按钮
- (void)deleteShopAction:(UIBarButtonItem *)rightBtn {
    
    self.selectAllButton.selected = self.selecedAllBtn.selected;
    if ([rightBtn.title isEqualToString:@"编辑"]) {
//        deleteView.hidden = NO;
        self.deleteAllView.hidden = NO;
        [rightBtn setTitle:@"完成"];
        [self.goodsTableView reloadData];
    }
    else
    {
        [rightBtn setTitle:@"编辑"];
//        deleteView.hidden = YES;
         self.deleteAllView.hidden = YES;
        [self.goodsTableView reloadData];
    }
}

//批量删除处理事件
- (void)deleteDataAction:(UIButton *)sender {
    NSMutableArray *goodsId = [NSMutableArray array];
    for (NSDictionary *dic in self.editArray) {
        NSString *goodId = [dic objectForKey:@"goodsId"];
        [goodsId addObject:goodId];
    }
    [self deleteCartType:goodsId];
}

#pragma mark - tableviewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
//    return [self.cartInfoArray count];
    
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{

    return CYGoodsSectionHeight;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.cartInfoArray.count > 0) {
        
            self.shopCartBtnView.hidden = NO;
    }
    return self.cartInfoArray.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    if (section==0)
        return 0.1;
    else
        return CYHeaderHeight;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSDictionary *goodsDictionary = nil;
    if (self.cartInfoArray.count > indexPath.row) {
       goodsDictionary = self.cartInfoArray[indexPath.row];
    }
    
    
    DLog(@"%zd",indexPath.row);
          
    
    if ([goodsDictionary[@"sellType"] integerValue] == 1 || [goodsDictionary[@"sellType"] integerValue] == 3)
    {
        CYCartGoodsModel *model = self.goodsArray[indexPath.row];
        
        transferGoodsCell *cell = [tableView dequeueReusableCellWithIdentifier:CYTransferGoodsCellIdentifier];
        
        cell.goodsModel = model;
        
        return cell;
    }
    else
    {
    // 判断商品是否下架，没下架是一种cell，下架用另外一种cell复用标识
        if ([[goodsDictionary  objectForKey:@"unshelve"] integerValue] == 0)
        {
            
            ShopCartTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYCartCellIdentifier];
            
            //    NSInteger section=[indexPath section];
            
            
            float price;
            if ([[MyInfoModel sharedInstance].userType integerValue] == 1) {
                price = [[goodsDictionary objectForKey:@"vipPrice"] floatValue];
            }
            else
            {
                price = [[goodsDictionary objectForKey:@"goodsPrice"] floatValue];
            }
            
            // 价格
            // float price=[[[self.cartInfoArray objectAtIndex:indexPath.section] objectForKey:@"goodsPrice"] floatValue];
            // 商品数量
            NSInteger goodsNum=[[goodsDictionary objectForKey:@"cartGoodsNumber"] integerValue];
            
            // cell.desImgView.image=[UIImage imageNamed:@"goods_icon_default.png"];
            // 商品图片地址
            NSString *urlStr = [NSString stringWithFormat:@"%@?x-oss-process=image/resize,m_lfit,h_500,w_500", [[self.cartInfoArray objectAtIndex:indexPath.row] objectForKey:@"goodsPic"]];
            NSURL *imageUrl=[NSURL URLWithString:urlStr];
            
            [cell.desImgView setImageWithURL:imageUrl
                            placeholderImage:UIIMAGE(@"goods_icon_default.png")];
            
            cell.priceLabel.text=[NSString stringWithFormat:@"￥%.2f",price];
            cell.priceLabel.textColor = [UIColor_HEX colorWithHexString:@"#ff5a1e"];
            cell.goodsNumLabel.text=[NSString stringWithFormat:@"%ld",(long)goodsNum];
            
            cell.goodsTitleLabel.text=[[self.cartInfoArray objectAtIndex:indexPath.row]
                                                            objectForKey:@"goodsName"];
            
            cell.goodsNumLabel.textColor = [UIColor_HEX colorWithHexString:@"#181818"];
            
            cell.deleteShop.hidden = YES;
            cell.selectBtn.hidden = NO;
            cell.rightAddBtn.enabled = YES;
            cell.leftDeletBtn.enabled = YES;
            
            //        cell.selectBtn.hidden = YES;

            
                if ([[goodsDictionary objectForKey:@"settlement"] floatValue]==1){
                    cell.selectBtn.selected=YES;
            //        cell.contentView.alpha = 1.0;
            //        cell.shadoView.layer.shadowColor = [[UIColor_HEX colorWithHexString:@"#dddddd"] CGColor];
            //
            //        cell.shadoView.layer.shadowOffset = CGSizeMake(0, 4);
            //
            //        cell.shadoView.layer.shadowOpacity = 0.5;
            //
            //        cell.shadoView.layer.shadowRadius = 1;
            
                }else{
                    cell.selectBtn.selected=NO;
            //        cell.contentView.alpha = 0.5;
                }
        
            
            //选择商品按钮
            //    [cell.selectBtn addTarget:self action:@selector(selectedGoodsAction:) forControlEvents:UIControlEventTouchUpInside];
            [cell.selectBtn setTag:indexPath.row];
            
            //删除商品数量按钮
            //    [cell.leftDeletBtn addTarget:self action:@selector(deleteGoodsAction:) forControlEvents:UIControlEventTouchUpInside];
            [cell.leftDeletBtn setTag:indexPath.row];
            
            //增加商品数量按钮
            //    [cell.rightAddBtn addTarget:self action:@selector(addGoodsAction:) forControlEvents:UIControlEventTouchUpInside];
            [cell.rightAddBtn setTag:indexPath.row];
            
            //    //删除整个商品
            //    [cell.deletCellBtn addTarget:self action:@selector(deleteOneCellGoodsAction:) forControlEvents:UIControlEventTouchUpInside];
            //    [cell.deletCellBtn setTag:section];
            
            //    //删除整个扩展商品
            //    [cell.deletCellExtBtn addTarget:self action:@selector(deleteOneCellGoodsAction:)      forControlEvents:UIControlEventTouchUpInside];
            //    [cell.deletCellExtBtn setTag:section];
            //    cell.deletCellBtn.hidden = YES;
            //    cell.deletCellExtBtn.hidden = YES;
            
            cell.selectionStyle=UITableViewCellSelectionStyleNone;
            
            return cell;
        }
    
        
        // 下架
        else
        {
            ShopCartTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYUnshelveGoodsCellIdentifier];
            
            //    NSInteger section=[indexPath section];
            float price = [[goodsDictionary objectForKey:@"goodsPrice"] floatValue];
            MyInfoModel *myInfo = [MyInfoModel sharedInstance];
            if ([myInfo.userType integerValue] == 1) {
                price = [[goodsDictionary objectForKey:@"vipPrice"] floatValue];
            }
            else
            {
                // 价格
                price = [[goodsDictionary objectForKey:@"goodsPrice"] floatValue];
            }
            
            // 价格
            // float price=[[[self.cartInfoArray objectAtIndex:indexPath.section] objectForKey:@"goodsPrice"] floatValue];
            // 商品数量
            NSInteger goodsNum=[[goodsDictionary objectForKey:@"goodsNumber"] integerValue];
            
            // cell.desImgView.image=[UIImage imageNamed:@"goods_icon_default.png"];
            // 商品图片地址
            NSString *urlStr = [NSString stringWithFormat:@"%@?x-oss-process=image/resize,m_lfit,h_500,w_500", [[self.cartInfoArray objectAtIndex:indexPath.row]objectForKey:@"goodsPic"]];
            NSURL *imageUrl=[NSURL URLWithString:urlStr];
            [cell.desImgView setImageWithURL:imageUrl placeholderImage:UIIMAGE(@"goods_icon_default.png")];
            
            cell.priceLabel.text=[NSString stringWithFormat:@"￥%.2f",price];
            cell.priceLabel.textColor = [UIColor_HEX colorWithHexString:@"#ff5a1e"];
            cell.goodsNumLabel.text=[NSString stringWithFormat:@"%ld",(long)goodsNum];
            cell.goodsTitleLabel.text=[[self.cartInfoArray objectAtIndex:indexPath.row]
                                                            objectForKey:@"goodsName"];
            cell.goodsNumLabel.textColor = [UIColor lightGrayColor];
            
            cell.deleteShop.hidden = NO;
            cell.selectBtn.hidden = YES;
            cell.rightAddBtn.enabled = NO;
            cell.leftDeletBtn.enabled = NO;
            
            cell.selectionStyle=UITableViewCellSelectionStyleNone;
            return cell;
        }
        
//    ShopCartTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYCartCellIdentifier];
//    
////    NSInteger section=[indexPath section];
//  
//    
//    float price = [[goodsDictionary objectForKey:@"goodsPrice"] floatValue];
//    
//    //价格
////    float price=[[[self.cartInfoArray objectAtIndex:indexPath.section] objectForKey:@"goodsPrice"] floatValue];
//    // 商品数量
//    NSInteger goodsNum=[[goodsDictionary objectForKey:@"goodsNumber"] integerValue];
//    
////    cell.desImgView.image=[UIImage imageNamed:@"goods_icon_default.png"];
//    //商品图片地址
//    NSURL *imageUrl=[NSURL URLWithString:[[self.cartInfoArray objectAtIndex:indexPath.row] objectForKey:@"goodsPic"]];
//    [cell.desImgView setImageWithURL:imageUrl placeholderImage:UIIMAGE(@"goods_icon_default.png")];
//    
//    cell.priceLabel.text=[NSString stringWithFormat:@"￥%.2f",price];
//    cell.goodsNumLabel.text=[NSString stringWithFormat:@"%ld",(long)goodsNum];
//    cell.goodsTitleLabel.text=[[self.cartInfoArray objectAtIndex:indexPath.row] objectForKey:@"goodsName"];
//    
//    // 商品下架
//    if ([[goodsDictionary  objectForKey:@"unshelve"] integerValue] == 1) {
//        
//        cell.deleteShop.hidden = NO;
//        cell.selectBtn.hidden = YES;
//        cell.rightAddBtn.enabled = NO;
//        cell.leftDeletBtn.enabled = NO;
//    }
//
//    
//    
//    
//    
////    if (settlement==1){
////        cell.selectBtn.selected=YES;
////        //cell.contentView.alpha = 1.0;
//////        cell.shadoView.layer.shadowColor = [[UIColor_HEX colorWithHexString:@"#dddddd"] CGColor];
//////        
//////        cell.shadoView.layer.shadowOffset = CGSizeMake(0, 4);
//////        
//////        cell.shadoView.layer.shadowOpacity = 0.5;
//////        
//////        cell.shadoView.layer.shadowRadius = 1;
////        
////    }else{
////        cell.selectBtn.selected=NO;
////        //cell.contentView.alpha = 0.5;
////    }
//    //选择商品按钮
////    [cell.selectBtn addTarget:self action:@selector(selectedGoodsAction:) forControlEvents:UIControlEventTouchUpInside];
//    [cell.selectBtn setTag:indexPath.section];
//    
//    //删除商品数量按钮
////    [cell.leftDeletBtn addTarget:self action:@selector(deleteGoodsAction:) forControlEvents:UIControlEventTouchUpInside];
//    [cell.leftDeletBtn setTag:indexPath.section];
//    
//    //增加商品数量按钮
////    [cell.rightAddBtn addTarget:self action:@selector(addGoodsAction:) forControlEvents:UIControlEventTouchUpInside];
//    [cell.rightAddBtn setTag:indexPath.section];
//    
////    //删除整个商品
////    [cell.deletCellBtn addTarget:self action:@selector(deleteOneCellGoodsAction:) forControlEvents:UIControlEventTouchUpInside];
////    [cell.deletCellBtn setTag:section];
//    
////    //删除整个扩展商品
////    [cell.deletCellExtBtn addTarget:self action:@selector(deleteOneCellGoodsAction:) forControlEvents:UIControlEventTouchUpInside];
////    [cell.deletCellExtBtn setTag:section];
////    cell.deletCellBtn.hidden = YES;
////    cell.deletCellExtBtn.hidden = YES;
//    
//    cell.selectionStyle=UITableViewCellSelectionStyleNone;
//    
//    return cell;
    }
    
    
}

#pragma mark - tableviewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    // 原来进入过购物车，从这个页面返回购物车；
    NSDictionary *currentDic= [[self.cartInfoArray objectAtIndex:indexPath.row] mutableCopy];
    if (self.commodityTag == -100) {
        [self.delegate getGoods:[currentDic objectForKey:@"goodsId"]];
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    // 商品过期过期或者换购商品，不能跳转
    if ([[currentDic objectForKey:@"unshelve"] integerValue] == 1 || [[currentDic objectForKey:@"sellType"] integerValue] == 1)
    {
        return;
    }
    
    CommodityDetailsViewController * commodityDetailsController = [[CommodityDetailsViewController alloc]init];
    commodityDetailsController.cartShop = -10;
//    commodityDetailsController.commodityDic = currentDic;
    commodityDetailsController.goodsId = [currentDic objectForKey:@"goodsId"];
    self.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:commodityDetailsController animated:YES];
    self.hidesBottomBarWhenPushed = NO;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView
        commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
        forRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    NSInteger index = indexPath.section;
//    NSMutableDictionary *currentDic= [[self.cartInfoArray objectAtIndex:index] mutableCopy];
//    
//    int goodsNumber=[[currentDic objectForKey:@"goodsNumber"] intValue];
//    NSString *goodsNumStr=[NSString stringWithFormat:@"%d",goodsNumber];
//    
//    int goodsId=[[currentDic objectForKey:@"goodsId"] intValue];
//    NSString *goodsIdStr=[NSString stringWithFormat:@"%d",goodsId];
//    
//    [self editCartType:TYPE_DELECELL goodsId:goodsIdStr number:goodsNumStr];
    [self editGoodsWithSender:indexPath.row goodsNumSerial:kGoodsNumKeep];

}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView
                  editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewRowAction *delete = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault
                                                                      title:@"删除"
                                                                    handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
//            NSInteger index = indexPath.section;
//            NSMutableDictionary *currentDic= [[self.cartInfoArray objectAtIndex:index] mutableCopy];
//        
//            int goodsNumber=[[currentDic objectForKey:@"goodsNumber"] intValue];
//            NSString *goodsNumStr=[NSString stringWithFormat:@"%d",goodsNumber];
//        
//            int goodsId=[[currentDic objectForKey:@"goodsId"] intValue];
//            NSString *goodsIdStr=[NSString stringWithFormat:@"%d",goodsId];
//        
//            [self editCartType:TYPE_DELECELL goodsId:goodsIdStr number:goodsNumStr];
        
        [self editGoodsWithSender:indexPath.row goodsNumSerial:kGoodsNumKeep];

        
    }];
    
    delete.backgroundColor = [UIColor_HEX colorWithHexString:@"ff5a1e"];
    
    return @[delete];
}


#pragma mark - ShopCartCellDelegate

//添加商品方法
-(void)addGoodsAction:(UIButton *)sender{
    
    NSInteger index=[(UIButton *)sender tag];
    NSMutableDictionary *currentDic= [[self.cartInfoArray objectAtIndex:index] mutableCopy];
    
    int goodsNumber=[[currentDic objectForKey:@"cartGoodsNumber"] intValue];
    NSString *goodsNumStr=[NSString stringWithFormat:@"%d",goodsNumber+1];
    
    int goodsId=[[currentDic objectForKey:@"goodsId"] intValue];
    NSString *goodsIdStr=[NSString stringWithFormat:@"%d",goodsId];
    
    mySettlement = @"1";
    [self editCartType:TYPE_EDITGOODS goodsId:goodsIdStr number:goodsNumStr];
//
//    
//    [self editGoodsWithSender:sender.tag goodsNumSerial:kGoodsNumUp];
}


//删除商品方法
-(void)deleteGoodsAction:(UIButton *)sender{
    
//    NSInteger index=[(UIButton *)sender tag];
//    NSMutableDictionary *currentDic= [[self.cartInfoArray objectAtIndex:index] mutableCopy];
//    
//    int goodsNumber=[[currentDic objectForKey:@"goodsNumber"] intValue];
//    NSString *goodsNumStr=[NSString stringWithFormat:@"%d",goodsNumber-1];
//    
//    int goodsId=[[currentDic objectForKey:@"goodsId"] intValue];
//    NSString *goodsIdStr=[NSString stringWithFormat:@"%d",goodsId];
//    mySettlement = @"1";
//    
//    if (goodsNumber>1) {
//        [self editCartType:TYPE_EDITGOODS goodsId:goodsIdStr number:goodsNumStr];
//    }
//
    
    [self editGoodsWithSender:sender.tag goodsNumSerial:kGoodsNumDecade];
    
}

- (void)editGoodsWithSender:(NSInteger)sender goodsNumSerial:(goodsNumTrend)goodsNumberTrend
{
    NSMutableDictionary *currentDic= [[self.cartInfoArray objectAtIndex:sender] mutableCopy];
    
    int goodsNumber=[[currentDic objectForKey:@"cartGoodsNumber"] intValue];
    NSString *goodsNumStr=[NSString stringWithFormat:@"%d",goodsNumber + goodsNumberTrend];
    
    int goodsId=[[currentDic objectForKey:@"goodsId"] intValue];
    NSString *goodsIdStr=[NSString stringWithFormat:@"%d",goodsId];
    
    if(goodsNumberTrend != 0)
    {
        mySettlement = @"1";
        
        // 减少商品数量
        if (goodsNumber>1 && goodsNumberTrend == -1) {
            [self editCartType:TYPE_EDITGOODS goodsId:goodsIdStr number:goodsNumStr];
        }
        // 商品数量已经为1并且继续点击减号
        else if (goodsNumber == 1 && goodsNumberTrend == -1)
        {
            [SRMessage infoMessage:@"你确定不要我了么？" block:^{
                
                [self editCartType:TYPE_DELECELL goodsId:goodsIdStr number:goodsNumStr];
            }];
        }
        // 商品数量增加
        else if(goodsNumberTrend == 1)
        {
            [self editCartType:TYPE_EDITGOODS goodsId:goodsIdStr number:goodsNumStr];
        }
    }
    // 左滑删除商品
    else
    {
        [self editCartType:TYPE_DELECELL goodsId:goodsIdStr number:goodsNumStr];
    }
}


//单选
-(void)selectedGoodsAction:(UIButton *)sender
{
    NSMutableDictionary *currentDic= [[self.cartInfoArray objectAtIndex:sender.tag] mutableCopy];
    //    NSIndexPath * indexPath = [NSIndexPath indexPathForRow:0 inSection:sender.tag];
    //    ShopCartTableViewCell * cell =(ShopCartTableViewCell *)[self.goodsTableView cellForRowAtIndexPath:indexPath];
    
    if (sender.selected==YES){
        sender.selected = NO;
        
        [self.editArray removeObject:currentDic];
        [currentDic setObject:@"0" forKey:@"settlement"];
        //cell.contentView.alpha = 0.5;
        
        //if (deleteView.hidden == YES) {
        mySettlement = @"0";
        [self editCartType:TYPE_EDITGOODS
                   goodsId:[currentDic objectForKey:@"goodsId"]
                    number:[currentDic objectForKey:@"goodsNumber"]];
        //}
        
    }
    else{
        sender.selected=YES;
        if (sender.tag < self.editArray.count) {
            [self.editArray insertObject:currentDic atIndex:sender.tag];
        }else{
            [self.editArray addObject:currentDic];
        }
        //cell.contentView.alpha = 1;
        [currentDic setObject:@"1" forKey:@"settlement"];
        
        //if (deleteView.hidden == YES) {
        mySettlement = @"1";
        [self editCartType:TYPE_EDITGOODS
                   goodsId:[currentDic objectForKey:@"goodsId"]
                    number:[currentDic objectForKey:@"goodsNumber"]];
        //}
    }
    [self.cartInfoArray replaceObjectAtIndex:sender.tag withObject:currentDic];
    // 不是全选情况
    if (self.cartInfoArray.count != self.editArray.count) {
        self.selecedAllBtn.selected = NO;
        self.selectAllButton.selected = NO;
    }else{
        self.selecedAllBtn.selected = YES;
        self.selectAllButton.selected = YES;
    }
    
    // 将所有的商品全部selecte
    selectAll.selected = self.selecedAllBtn.selected;
    
    [self traverseGoodsInfo:self.editArray];
}




//-(void)deleteOneCellGoodsAction:(id)sender{
//    
//    NSInteger index=[(UIButton *)sender tag];
//    NSMutableDictionary *currentDic= [[self.cartInfoArray objectAtIndex:index] mutableCopy];
//    
//    int goodsNumber=[[currentDic objectForKey:@"goodsNumber"] intValue];
//    NSString *goodsNumStr=[NSString stringWithFormat:@"%d",goodsNumber];
//    
//    int goodsId=[[currentDic objectForKey:@"goodsId"] intValue];
//    NSString *goodsIdStr=[NSString stringWithFormat:@"%d",goodsId];
//    
//    [self editCartType:TYPE_DELECELL goodsId:goodsIdStr number:goodsNumStr];
//}

#pragma -mark 获取购物车信息  
/**
 *  请求购物车信息
 */
-(void)requestShopInfo{
    if ([self noNetwork]) {
        return;
    }
    
    NSDictionary *paramsDic=@{};
    
    [_cloudClient requestMethodWithMod:@"cart/getCartInfo"
                                params:nil
                            postParams:paramsDic
                              delegate:self
                              selector:@selector(requestCartInfoSuccess:)
                         errorSelector:@selector(requestCartInfoFail:)
                      progressSelector:nil];
}

/**
 *  购物车数据请求成功
 *
 *  @param response 返回数据
 */
-(void)requestCartInfoSuccess:(NSDictionary*)response{
    [super hidenHUD];
    if ([DataCheck isValidDictionary:response]) {
        
        NSString *number = response[@"cartInfo"][@"cartNumber"];
        [[TabBarController sharedInstance] setShopCartNumberAction:number];
    }
//    response = @{
//        @"cartInfo":@{
//            @"cartNumber":@"9",
//            @"cartPrice":@"9",
//            @"cartShipping":@"差1.00元免运费"
//        },
//        @"goodsList":@[
//                     @{
//                         @"goodsId":@"9",
//                         @"cid":@"6",
//                         @"goodsName":@"测试商品9",
//                         @"goodsPrice":@"1",
//                         @"vipPrice":@"11",
//                         @"goodsPic":@"http://maiya-prod.oss-cn-shenzhen.aliyuncs.com/image/psu.jpg",
//                         @"goodsNumber":@"9",
//                         @"settlement":@"1",
//                         @"unshelve":@"0",
//                         @"tip":@"",
//                         @"maxBuy":@"100"
//                     }
//                     ]
//        };
    
    [response writeToFile:@"/Users/eqbang/Desktop/进入购物车的数据.plist" atomically:NO];
    
    if ([DataCheck isValidArray:[response objectForKey:@"goodsList"]]) {
        
        // 免配送费规则
//        [[CommClass sharedCommon] setObject:[response objectForKey:@"rulePrice"] forKey:CART_STANDARDFEE];
        
        self.cartInfoArray = [[response objectForKey:@"goodsList"] mutableCopy];
        
        // 购物车商品模型数组
        self.goodsArray = [CYCartGoodsModel mj_objectArrayWithKeyValuesArray:response[@"goodsList"]];
        
        // 购物车信息模型数组
        self.infoArray = [CYCartInfoModel mj_objectArrayWithKeyValuesArray:@[response[@"cartInfo"]]];
                
        // 购物车信息模型
//        CYCartInfoModel *info = self.infoArray.firstObject;
//        self.priceLabel.text = [NSString stringWithFormat:@"%.2f",info.cartPrice];
//        DLog(@"%.2f",info.cartPrice);
//        self.numLabel.text=[NSString stringWithFormat:@"%ld件",(long)info.cartNumber];
//        
//        self.diffPriceLabel.text = info.cartShipping;
        
        // 遍历所有的商品,选出被选中的
//        for (NSDictionary *dict in self.cartInfoArray)
//        {
//            if ([[dict objectForKey:@"settlement"] integerValue] == 1)
//            {
//                [self.editArray addObject:dict];
//            }
//        }
//        if (self.editArray.count < self.cartInfoArray.count)
//        {
//            self.selecedAllBtn.selected = NO;
//        }else
//        {
//            self.selecedAllBtn.selected = YES;
//        }
        
        [self traverseGoodsInfo:self.cartInfoArray];
        [self.goodsTableView reloadData];
        self.emptyView.hidden=YES;
    }
    // 购物车中没有货物
    else{
        self.emptyView.hidden=NO;
        self.cartInfoArray = [NSMutableArray array];
        self.diffPriceLabel.text = nil;
        NSDictionary *cartInfo=@{@"cartNumber":@0,@"cartPrice":@0,@"cartShipping":@""};
        ShoppingCartModel *cartModel=[ShoppingCartModel shareModel];
        [cartModel updateShoppingCartInfo:cartInfo];
//        [self traverseGoodsInfo:self.cartInfoArray];
    }
    
    // 进入之后，显示navBar右边的编辑按钮
    if (self.cartInfoArray.count > 0) {
        self.navigationItem.rightBarButtonItem = rightButton;
//        self.deleteAllView.hidden = NO;

    }
    else
    {
        self.navigationItem.rightBarButtonItem = nil;
//        self.deleteAllView.hidden = YES;

    }
}

// 刷新失败之后，隐藏HUD
-(void)requestCartInfoFail:(NSDictionary*)response{
    [super hidenHUD];
}


/**
 * Method name: traverseGoodsInfo
 * Description: 计算购物车里面的价钱 和商品数量
 * Parameter: goodsArray
 */
-(void)traverseGoodsInfo:(NSMutableArray *)goodsArray{
    
    __block NSInteger goodsNum=0;
    __block float goodsPrice=0;
    self.editArray = [NSMutableArray array];
    
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
        
        // 子线程计算
        for (NSDictionary *dict in goodsArray)
        {
            NSInteger  tmpGoodsNum= [[dict objectForKey:@"cartGoodsNumber"] integerValue];
//            if ([DataCheck isValidNumber:[dict objectForKey:@"goodsPrice"]])
            if ([dict objectForKey:@"goodsPrice"])
            {
                float tmpgoodsPrice= [[dict objectForKey:@"goodsPrice"] floatValue]*tmpGoodsNum;
                
                if ([[dict objectForKey:@"settlement"] integerValue] == 1) {
                    
                    goodsNum+=tmpGoodsNum;
                    goodsPrice+=tmpgoodsPrice;
                    
                    [self.editArray addObject:dict];
                }

            }
            
        }
        
        NSString *price=[NSString stringWithFormat:@"%.2f",goodsPrice];
        NSString *num=[NSString stringWithFormat:@"%ld",(long)goodsNum];
        
        // 回主线程更新界面
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            
            CYCartInfoModel *info = self.infoArray.firstObject;
//            self.priceLabel.text = [NSString stringWithFormat:@"%.2f",info.cartPrice];
//            DLog(@"%.2f",info.cartPrice);
//            self.numLabel.text=[NSString stringWithFormat:@"%ld件",(long)info.cartNumber];
            
            self.diffPriceLabel.text = info.cartShipping;
            
            self.priceLabel.text=[NSString stringWithFormat:@"￥%.2f",info.cartPrice];
            self.numLabel.text=[NSString stringWithFormat:@"%ld件",(long)goodsNum];
            [self.choseOkBtn setTitle:[NSString stringWithFormat:@"  去下单（共%ld件）", (long)goodsNum] forState:UIControlStateNormal];
            
//            float diffPrice=0;
//            NSInteger cartStandardfee = [[[CommClass sharedCommon] objectForKey:CART_STANDARDFEE] integerValue];
//            if ((cartStandardfee - goodsPrice)>0) {
//                diffPrice=cartStandardfee-goodsPrice;
//                self.diffPriceLabel.text=[NSString stringWithFormat:@"差%.2f元免配送费",diffPrice];
//            }
//            else{
//                self.diffPriceLabel.text=@"免配送费";
//            }
            

            
            NSDictionary *cartInfo=@{@"cartNumber":num,
                                     @"cartPrice":price,
                                     @"cartShipping":self.diffPriceLabel.text};
//            NSDictionary *cartInfo = @{@"cartNumber":self.numLabel.text,@"cartPrice":self.priceLabel.text,@"cartShipping":info.cartShipping};
            
            if (self.cartInfoArray.count != self.editArray.count) {
                self.selecedAllBtn.selected = NO;
                // 更新购物车的信息
                ShoppingCartModel *cartModel=[ShoppingCartModel shareModel];
                [cartModel updateShoppingCartInfo:cartInfo];
            }else{
                self.selecedAllBtn.selected = YES;
                ShoppingCartModel *cartModel=[ShoppingCartModel shareModel];
                [cartModel updateShoppingCartInfo:cartInfo];
            }

        }];
    }];
    
//    for (int i=0; i<[goodsArray count]; i++) {
//        
//        NSDictionary *currentDic=[goodsArray objectAtIndex:i];
//        
//        NSInteger  tmpGoodsNum= [[currentDic objectForKey:@"goodsNumber"] integerValue];
//        float tmpgoodsPrice= [[currentDic objectForKey:@"goodsPrice"] floatValue]*tmpGoodsNum;
//        
//        if ([[currentDic objectForKey:@"settlement"] integerValue] == 1) {
//            goodsNum+=tmpGoodsNum;
//            goodsPrice+=tmpgoodsPrice;
//            [self.editArray addObject:currentDic];
//        }
//    }

    
    for (int i = 0; i < self.cartInfoArray.count; i++) {
        NSDictionary * dic = [self.cartInfoArray objectAtIndex:i];
        NSMutableDictionary * mutDic = [NSMutableDictionary dictionaryWithDictionary:dic];
        if ([[mutDic objectForKey:@"settlement"] integerValue] == 0 && [[dic objectForKey:@"unshelve"] integerValue] == 0) {
            self.selecedAllBtn.selected = NO;
            self.selectAllButton.selected = NO;
            return;
        }
        else if ([[dic objectForKey:@"unshelve"] integerValue] == 0 && [[mutDic objectForKey:@"settlement"] integerValue] == 1)
        {
            self.selecedAllBtn.selected = YES;
            self.selectAllButton.selected = YES;
        }
    }
    
    selectAll.selected = self.selecedAllBtn.selected;
}


#pragma -mark 结算购物车

-(void)settlementShoppingCart{
    
    if ([self isNotNetwork]) {
        [SRMessage infoMessage:@"网络异常，请检查您的网络。" delegate:self];
        return;
    }
    [super showHUD];
    
    ShoppingCartModel *cartModel=[ShoppingCartModel shareModel];
    
    
    NSDictionary *paramsDic=@{@"goodsList":self.editArray,
                              @"totalPrice":[cartModel goodsPrice],
                              @"couponId":@"0",
                              };
    
    [_cloudClient requestMethodWithMod:@"order/flow"
                                params:nil
                            postParams:paramsDic
                              delegate:self
                              selector:@selector(settlementSuccess:)
                         errorSelector:@selector(settlementFail:)
                      progressSelector:nil];
}

//成功
-(void)settlementSuccess:(NSDictionary *)response{
    [super hidenHUD];
    if ([DataCheck isValidDictionary:response]) {
        
        self.settlementDic=[[NSDictionary alloc]initWithDictionary:response];
        
        ConfirmOrderController *confirmControll=[[ConfirmOrderController alloc]
                                                 initWithNibName:@"ConfirmOrderController"
                                                          bundle:nil];
        confirmControll.orderInfoDic=[[NSDictionary alloc]initWithDictionary:self.settlementDic];
        self.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:confirmControll animated:YES];
        self.hidesBottomBarWhenPushed = NO;
    }
    
}
//失败
-(void)settlementFail:(NSDictionary *)response{
    [super hidenHUD];
    
}

#pragma -mark  编辑购物车
/**
 *  编辑购物车
 *
 *  @param editType 编辑类型
 *  @param goodsId  商品ID
 *  @param number   商品数量
 */
-(void)editCartType:(NSString *)editType goodsId:(NSString *)goodsId number:(NSString *)number{
    [self showHUD];
    if (!mySettlement) {
        mySettlement = @"";
    }
    
    NSDictionary *paramsDic=@{@"type":editType,
                              @"goodsId":goodsId,
                              @"number":number,
                              @"settlement":mySettlement};
    
    [_cloudClient requestMethodWithMod:@"cart/editCart"
                                params:nil
                            postParams:paramsDic
                              delegate:self
                              selector:@selector(editSuccess:)
                         errorSelector:@selector(editFail:)
                      progressSelector:nil];
}

// 成功
-(void)editSuccess:(NSDictionary*)response{
    
    [self hidenHUD];
    if ([DataCheck isValidDictionary:response]) {
        
        NSString *number = response[@"cartInfo"][@"cartNumber"];
        [[TabBarController sharedInstance] setShopCartNumberAction:number];
    }
    
    [response writeToFile:@"/Users/eqbang/Desktop/44444.plist" atomically:YES];
    
    if ([DataCheck isValidArray:[response objectForKey:@"goodsList"]]) {
        self.cartInfoArray=[[response objectForKey:@"goodsList"] mutableCopy];
        
        self.goodsArray = [CYCartGoodsModel mj_objectArrayWithKeyValuesArray:response[@"goodsList"]];
        // 购物车信息模型数组
        self.infoArray = [CYCartInfoModel mj_objectArrayWithKeyValuesArray:@[response[@"cartInfo"]]];
        
        [self traverseGoodsInfo:self.cartInfoArray];
        
//        NSArray *cartList = [response objectForKey:@"cartHomeTotalList"];
//        NSArray *cartList = [response objectForKey:@"cartInfo"];
//        NSDictionary* cartInfo=[self formatSpecialArray:cartList];
        
        NSDictionary *cartInfo = response[@"cartInfo"];
        
        //更新购物车数据
        ShoppingCartModel *cartModel=[ShoppingCartModel shareModel];
        [cartModel updateShoppingCartInfo:cartInfo];
        //self.editArray=[self.cartInfoArray mutableCopy];
        [self.goodsTableView reloadData];
    }
    else {
        self.cartInfoArray=[NSMutableArray array];
        [self traverseGoodsInfo:self.cartInfoArray];
        self.editArray=[self.cartInfoArray mutableCopy];
        [self.goodsTableView reloadData];
        self.emptyView.hidden=NO;
        
        self.navigationItem.rightBarButtonItem = nil;
        deleteView.hidden = YES;
    }
    
}

// 编辑失败
-(void)editFail:(NSDictionary*)response{
    [self hidenHUD];
    
}

#pragma mark - 批量删除相关

//购物车批量删除
-(void)deleteCartType:(NSArray *)goodIds{

    NSDictionary *paramsDic=@{@"goodsId":goodIds};
    
    [_cloudClient requestMethodWithMod:@"cart/delete"
                                params:nil
                            postParams:paramsDic
                              delegate:self
                              selector:@selector(deleteCartSuccess:)
                         errorSelector:@selector(deleteCartFail:)
                      progressSelector:nil];
}

// 成功删除
-(void)deleteCartSuccess:(NSDictionary*)response{
    
    if ([DataCheck isValidArray:[response objectForKey:@"goodsList"]]) {
        self.cartInfoArray=[[response objectForKey:@"goodsList"] mutableCopy];
        // 购物车商品模型数组
        self.goodsArray = [CYCartGoodsModel mj_objectArrayWithKeyValuesArray:response[@"goodsList"]];
        [self traverseGoodsInfo:nil];
        NSArray *cartList = [response objectForKey:@"cartHomeTotalList"];
        NSDictionary* cartInfo=[self formatSpecialArray:cartList];
        
        //更新购物车数据
        ShoppingCartModel *cartModel=[ShoppingCartModel shareModel];
        [cartModel updateShoppingCartInfo:cartInfo];
        
        //self.editArray=[self.cartInfoArray mutableCopy];
        [self.goodsTableView reloadData];
    }
    else {
        self.cartInfoArray=[NSMutableArray array];
        [self traverseGoodsInfo:self.cartInfoArray];
        self.editArray=[self.cartInfoArray mutableCopy];
        [self.goodsTableView reloadData];
        self.emptyView.hidden=NO;
        
        self.navigationItem.rightBarButtonItem = nil;
        deleteView.hidden = YES;
    }
    
}

// 失败的删除
-(void)deleteCartFail:(NSDictionary*)response{
    
    
}


#pragma -mark  按钮点击事件 结算进入下一页
//选好结算跳转到下一页
-(IBAction)chosen:(id)sender{
    [MobClick event:Cfm_Shopping];
    [self settlementShoppingCart];
    
}




#pragma mark - 删除view相关操作
/** 点击全选按钮 */
- (IBAction)selecAllGoods:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.selecedAllBtn.selected = !sender.selected;
    self.selectAllButton.selected = self.selecedAllBtn.selected;
    [self futureGenerations:sender];
}

/** 点击删除按钮 */
- (IBAction)deleteAllGoods:(id)sender {
    
    [self deleteDataAction:sender];
}

//点击全选  左边圆圈button
-(IBAction)futureGenerations:(id)sender{
    
    for (int i = 0; i < self.cartInfoArray.count; i ++) {
        NSDictionary * dic = [self.cartInfoArray objectAtIndex:i];
        NSMutableDictionary * mutDic = [NSMutableDictionary dictionaryWithDictionary:dic];
        if (self.selecedAllBtn.selected == YES) {
            [mutDic setObject:@"0" forKey:@"settlement"];
        }else{
            [mutDic setObject:@"1" forKey:@"settlement"];
        }
        [self.cartInfoArray replaceObjectAtIndex:i
                                      withObject:[NSDictionary dictionaryWithDictionary:mutDic]];
    }
    
    if (self.selecedAllBtn.selected == NO) {
        self.selecedAllBtn.selected = YES;
        self.selectAllButton.selected = YES;

        self.editArray = [NSMutableArray arrayWithArray:self.cartInfoArray];
        
        [self editCartType:@"3" goodsId:@"" number:@""];
        [self traverseGoodsInfo:self.editArray];
    }else{
        mySettlement = @"0";
        self.selecedAllBtn.selected = NO;
        self.selectAllButton.selected = NO;
        [self.editArray removeAllObjects];
        self.priceLabel.text=@"￥0.00";
        self.numLabel.text=@"0件";
        [self.choseOkBtn setTitle:@"  去下单（共0件）" forState:UIControlStateNormal];
        self.diffPriceLabel.text = @"免运费";
        [self editCartType:@"4" goodsId:@"" number:@""];
    }
    
    selectAll.selected = self.selecedAllBtn.selected;
    
    [self.goodsTableView reloadData];
}

- (void)disMIssViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissSelf
{
    if (toHome == YES) {
        [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"AUTODISMISS"];
        TabBarController *tabBar = [TabBarController sharedInstance];
        tabBar.selectedIndex = 0;
        [self dismissViewControllerAnimated:NO completion:nil];
    }
    else
    {
        toHome = YES;
    }
    
}




@end
