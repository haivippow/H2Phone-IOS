#import "H2MainController.h"
#import "H2ConfigManager.h"
#import "H2AppListController.h"
#import "H2BrowserController.h"

@interface H2MainController ()
@property (nonatomic, strong) UISwitch *fakeSwitch;
@end

@implementation H2MainController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"H2Changer";
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.fakeSwitch = [UISwitch new];
    [self.fakeSwitch addTarget:self action:@selector(toggleFake:) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.fakeSwitch.on = [[H2ConfigManager.sharedManager snapshot][@"enabled"] boolValue];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 6; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return section == 2 ? [H2ConfigManager profiles].count : 1; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @[@"Dashboard", @"Test Apps", @"Profiles", @"Web Browser", @"Control", @"Debug Logs"][section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    NSDictionary *config = [H2ConfigManager.sharedManager snapshot];
    switch (indexPath.section) {
        case 0:
            cell.textLabel.text = [NSString stringWithFormat:@"Fake %@", [config[@"enabled"] boolValue] ? @"ON" : @"OFF"];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Active profile: %@", config[@"profile"]];
            cell.accessoryView = self.fakeSwitch;
            break;
        case 1:
            cell.textLabel.text = @"Choose apps";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu selected", (unsigned long)[config[@"enabledApps"] count]];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case 2:
            cell.textLabel.text = [H2ConfigManager profiles][indexPath.row][@"name"];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · iOS %@", [H2ConfigManager profiles][indexPath.row][@"model"], [H2ConfigManager profiles][indexPath.row][@"ios"]];
            cell.accessoryType = [config[@"profile"] isEqualToString:[H2ConfigManager profiles][indexPath.row][@"name"]] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        case 3:
            cell.textLabel.text = @"Open browser with profile User-Agent";
            cell.detailTextLabel.text = [config[@"enabled"] boolValue] ? @"Fake UA is ON" : @"Original UA (Fake OFF)";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case 4:
            cell.textLabel.text = @"Restore Original";
            cell.detailTextLabel.text = @"Turn Fake OFF; real API values return on next read";
            break;
        default:
            cell.textLabel.text = @"Show recent logs";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

- (void)showError:(NSError *)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Save failed" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)toggleFake:(UISwitch *)sender {
    NSError *error;
    NSString *profile = [H2ConfigManager.sharedManager snapshot][@"profile"];
    if (![H2ConfigManager.sharedManager saveEnabled:sender.on profile:profile error:&error]) {
        sender.on = !sender.on;
        [self showError:error];
    }
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        [self.navigationController pushViewController:[H2AppListController new] animated:YES];
    } else if (indexPath.section == 2) {
        NSError *error;
        NSString *profile = [H2ConfigManager profiles][indexPath.row][@"name"];
        BOOL enabled = [[H2ConfigManager.sharedManager snapshot][@"enabled"] boolValue];
        if (![H2ConfigManager.sharedManager saveEnabled:enabled profile:profile error:&error]) [self showError:error];
        [self.tableView reloadData];
    } else if (indexPath.section == 3) {
        [self.navigationController pushViewController:[H2BrowserController new] animated:YES];
    } else if (indexPath.section == 4) {
        NSError *error;
        if (![H2ConfigManager.sharedManager restoreOriginal:&error]) [self showError:error];
        self.fakeSwitch.on = NO;
        [self.tableView reloadData];
    } else if (indexPath.section == 5) {
        NSString *logs = [[H2ConfigManager.sharedManager recentLogs] componentsJoinedByString:@"\n"];
        UIViewController *viewer = [UIViewController new];
        viewer.title = @"Debug Logs";
        viewer.view.backgroundColor = UIColor.systemBackgroundColor;
        UITextView *textView = [[UITextView alloc] initWithFrame:viewer.view.bounds];
        textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        textView.editable = NO;
        textView.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
        textView.text = logs.length ? logs : @"No logs yet";
        [viewer.view addSubview:textView];
        [self.navigationController pushViewController:viewer animated:YES];
    }
}
@end
