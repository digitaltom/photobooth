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
    $scope.emailFormData = {}

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
      }).then(function successCallback() {
        $scope.alerts.push({type: 'success', msg: 'Pictureset ' + $routeParams.pictureSetId + ' destroyed'});
        $location.path( '/' );
      }, function errorCallback(response) {
        $rootScope.alerts.push({type: 'error', msg: response.data.error});
      });
    };

    $scope.send_email = function() {
      $http({
        method: 'POST',
        data: $scope.emailFormData,
        url: '/picture_sets/'+ $routeParams.pictureSetId + '/emails'
      }).then(function successCallback(response) {
        $scope.alerts.push({type: 'success', msg: 'Successfully sent email to ' + $scope.emailFormData.email});
        $location.path( '/' );
      }, function errorCallback(response) {
        $rootScope.alerts.push({type: 'error', msg: response.data.error});
      });
    };

    $scope.loadPictureSet()

    $scope.rw = (location.search != '?rw/');
    $scope.send_by_email = window.send_by_email;

  }]);
