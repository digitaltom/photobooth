photoBoothApp.controller('PictureSetCtrl', [
  '$scope',
  '$http',
  '$uibModal',
  '$log',
  '$routeParams',
  '$rootScope',
  '$location',
  function ($scope, $http, $uibModal, $log, $routeParams, $rootScope, $location) {

    $log.log('$routeParams.pictureSetId: ' + $routeParams.pictureSetId)
    $scope.pictureSetId = $routeParams.pictureSetId;

    $scope.loadPictureSet = function () {
      $http({
        method: 'GET',
        url: '/picture_sets/' + $routeParams.pictureSetId
      }).then(function successCallback(response) {
        $scope.picture_set = response.data;
      }, function errorCallback(response) {
        $rootScope.alerts.push({type: 'error', msg: response.data.error});
      });
    };

    $scope.destroy = function () {
      $http({
        method: 'DELETE',
        url: '/picture_sets/' + $routeParams.pictureSetId
      }).then(function successCallback(response) {
        $scope.alerts.push({type: 'success', msg: 'destroyed'});
        $location.path( "/main" );
      }, function errorCallback(response) {
        $rootScope.alerts.push({type: 'error', msg: response.data.error});
      });
    };

    $scope.loadPictureSet()

  }]);

