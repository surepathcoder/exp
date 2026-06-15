import 'package:flutter_riverpod/legacy.dart';
import '../models/project.dart';
import '../services/api_service.dart';

class ProjectState {
  final List<Project> projects;
  final List<Project> activeProjects;
  final bool isLoading;
  final String? error;

  ProjectState({
    this.projects = const [],
    this.activeProjects = const [],
    this.isLoading = false,
    this.error,
  });

  ProjectState copyWith({
    List<Project>? projects,
    List<Project>? activeProjects,
    bool? isLoading,
    String? error,
  }) {
    return ProjectState(
      projects: projects ?? this.projects,
      activeProjects: activeProjects ?? this.activeProjects,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProjectNotifier extends StateNotifier<ProjectState> {
  final ApiService _apiService;

  ProjectNotifier(this._apiService) : super(ProjectState());

  Future<void> fetchProjects() async {
    state = state.copyWith(isLoading: true);
    try {
      final allProjects = await _apiService.getProjects();
      final activeOnly = await _apiService.getProjects(activeOnly: true);
      state = state.copyWith(
        projects: allProjects,
        activeProjects: activeOnly,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<Project> addProject(Project project) async {
    state = state.copyWith(isLoading: true);
    try {
      final newProject = await _apiService.createProject(project);
      
      final updatedProjects = [newProject, ...state.projects];
      final updatedActive = newProject.status == ProjectStatus.active || newProject.status == ProjectStatus.upcoming
          ? [newProject, ...state.activeProjects]
          : state.activeProjects;

      state = state.copyWith(
        projects: updatedProjects,
        activeProjects: updatedActive,
        isLoading: false,
      );
      return newProject;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<bool> updateProject(int id, Project project) async {
    state = state.copyWith(isLoading: true);
    try {
      final updated = await _apiService.updateProject(id, project);
      final updatedList = state.projects.map((p) => p.id == id ? updated : p).toList();
      final updatedActive = updatedList
          .where((p) => p.status == ProjectStatus.active || p.status == ProjectStatus.upcoming)
          .toList();

      state = state.copyWith(
        projects: updatedList,
        activeProjects: updatedActive,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> deleteProject(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiService.deleteProject(id);
      final updatedList = state.projects.where((p) => p.id != id).toList();
      final updatedActive = state.activeProjects.where((p) => p.id != id).toList();

      state = state.copyWith(
        projects: updatedList,
        activeProjects: updatedActive,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }
}

final projectProvider = StateNotifierProvider<ProjectNotifier, ProjectState>((ref) {
  return ProjectNotifier(ref.watch(apiServiceProvider));
});
