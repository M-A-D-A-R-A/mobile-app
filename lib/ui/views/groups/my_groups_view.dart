import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:mobile_app/cv_theme.dart';
import 'package:mobile_app/locator.dart';
import 'package:mobile_app/models/groups.dart';
import 'package:mobile_app/services/dialog_service.dart';
import 'package:mobile_app/ui/components/cv_add_icon_button.dart';
import 'package:mobile_app/ui/views/base_view.dart';
import 'package:mobile_app/ui/views/groups/components/group_member_card.dart';
import 'package:mobile_app/ui/views/groups/components/group_mentor_card.dart';
import 'package:mobile_app/ui/views/groups/edit_group_view.dart';
import 'package:mobile_app/ui/views/groups/new_group_view.dart';
import 'package:mobile_app/utils/snackbar_utils.dart';
import 'package:mobile_app/viewmodels/groups/my_groups_viewmodel.dart';

class MyGroupsView extends StatefulWidget {
  const MyGroupsView({Key key}) : super(key: key);

  static const String id = 'my_groups_view';

  @override
  _MyGroupsViewState createState() => _MyGroupsViewState();
}

class _MyGroupsViewState extends State<MyGroupsView>
    with SingleTickerProviderStateMixin {
  final DialogService _dialogService = locator<DialogService>();
  MyGroupsViewModel _model;
  TabController _tabController;

  Widget _emptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SvgPicture.asset(
          'assets/images/group/no_group.svg',
          height: 250,
        ),
        _buildSubHeader(
            title: "Explore and join groups of your school and friends!"),
      ],
    );
  }

  Widget _buildSubHeader({String title}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 48.0),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headline6,
      ),
    );
  }

  Future<void> onCreateGroupPressed() async {
    var _result = await Get.toNamed(NewGroupView.id);

    if (_result is Group) _model.onGroupCreated(_result);
  }

  Future<void> onEditGroupPressed(Group group) async {
    var _result = await Get.toNamed(
      EditGroupView.id,
      arguments: group,
    );

    if (_result is Group) _model.onGroupUpdated(_result);
  }

  Future<void> onDeleteGroupPressed(String groupId) async {
    var _dialogResponse = await _dialogService.showConfirmationDialog(
      title: 'Delete Group',
      description: 'Are you sure you want to delete this group?',
      confirmationTitle: 'DELETE',
    );

    if (_dialogResponse.confirmed) {
      _dialogService.showCustomProgressDialog(title: 'Deleting Group');

      await _model.deleteGroup(groupId);

      _dialogService.popDialog();

      if (_model.isSuccess(_model.DELETE_GROUP)) {
        SnackBarUtils.showDark(
          'Group Deleted',
          'Group was successfully deleted.',
        );
      } else if (_model.isError(_model.DELETE_GROUP)) {
        SnackBarUtils.showDark(
          'Error',
          _model.errorMessageFor(_model.DELETE_GROUP),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<MyGroupsViewModel>(
      onModelReady: (model) {
        _model = model;
        _model.fetchMentoredGroups();
        _model.fetchMemberGroups();
        _tabController = TabController(length: 2, vsync: this);
      },
      builder: (context, model, child) => Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: onCreateGroupPressed,
          backgroundColor: CVTheme.primaryColor,
          child: const Icon(Icons.add),
        ),
        appBar: AppBar(
          title: TabBar(
            controller: _tabController,
            labelColor: CVTheme.textColor(context),
            indicatorColor: CVTheme.primaryColor,
            tabs: const [
              Tab(
                text: 'Mentored',
              ),
              Tab(
                text: 'Joined',
              ),
            ],
          ),
        ),
        body: Builder(
          builder: (context) {
            var _mentoredGroups = <Widget>[];
            var _joinedGroups = <Widget>[];

            if (_model.isSuccess(_model.FETCH_MENTORED_GROUPS)) {
              // creates GroupMentorCard corresponding to each mentor group
              for (var group in _model.mentoredGroups) {
                _mentoredGroups.add(
                  GroupMentorCard(
                    group: group,
                    onEdit: () => onEditGroupPressed(group),
                    onDelete: () => onDeleteGroupPressed(group.id),
                  ),
                );
              }
              // Adds fetch more groups icon if link to next set exists
              if (_model?.previousMentoredGroupsBatch?.links?.next != null) {
                _mentoredGroups.add(
                  CVAddIconButton(onPressed: _model.fetchMentoredGroups),
                );
              }
            }
            if (_model.isSuccess(_model.FETCH_MEMBER_GROUPS)) {
              // creates GroupMemberCard corresponding to each member group
              for (var group in _model.memberGroups) {
                _joinedGroups.add(GroupMemberCard(group: group));
              }

              // Adds fetch more groups icon if link to next set exists
              if (_model?.previousMemberGroupsBatch?.links?.next != null) {
                _joinedGroups.add(
                  CVAddIconButton(onPressed: _model.fetchMemberGroups),
                );
              }
            }

            return TabBarView(
              controller: _tabController,
              children: <Widget>[
                _mentoredGroups.isEmpty
                    ? _emptyState()
                    : ListView(
                        children: _mentoredGroups,
                      ),
                _joinedGroups.isEmpty
                    ? _emptyState()
                    : ListView(
                        children: _joinedGroups,
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}
